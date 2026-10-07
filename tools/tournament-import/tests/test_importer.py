import argparse
from datetime import date, datetime
import importlib.util
import os
from pathlib import Path
import sys
from unittest.mock import MagicMock

import pytest
from openpyxl import Workbook
from openpyxl.utils.datetime import CALENDAR_MAC_1904

MODULE = Path(__file__).parents[1] / 'import_tournaments.py'
spec = importlib.util.spec_from_file_location('importer', MODULE)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def row(**changes):
    values = dict(name='Cup', city='Bern', country='CH', club='Club', contactInformation='info@example.com', startDate='2026-11-01', endDate='2026-11-03')
    values.update(changes)
    return values


def workbook(tmp_path, records=None, headers=m.FIELDS, epoch=None):
    wb = Workbook()
    wb.active.title = 'Tournaments'
    if epoch:
        wb.epoch = epoch
    wb.active.append(headers)
    for record in records if records is not None else [row()]:
        wb.active.append([record.get(f) for f in headers])
    path = tmp_path / 'input.xlsx'
    wb.save(path)
    return path


def test_template(tmp_path):
    path = tmp_path / 'template.xlsx'
    m.template(path)
    with pytest.raises(m.ValidationError, match='No tournaments'):
        m.parse(path)


@pytest.mark.parametrize('changes, error', [
    ({'name': ''}, 'name: required'), ({'club': None}, 'club: required'),
    ({'startDate': '2026-02-30'}, 'startDate'), ({'startDate': '01/11/2026'}, 'startDate'),
    ({'endDate': '2026-11-01'}, 'endDate'), ({'endDate': '2026-11-07'}, 'endDate'),
    ({'signupDeadline': '2026-11-01'}, 'signupDeadline'),
    ({'contactInformation': 'bad'}, 'contactInformation'),
    ({'entryFee': '-1'}, 'entryFee'), ({'entryFee': 'nan'}, 'entryFee'),
    ({'entryFee': True}, 'entryFee'), ({'maxNumberOfTeams': 1.5}, 'maxNumberOfTeams'),
    ({'currency': 'XYZ'}, 'currency'), ({'name': '=1+1'}, 'formulas'),
    ({'name': 123}, 'expected text'),
])
def test_invalid(tmp_path, changes, error):
    with pytest.raises(m.ValidationError, match=error):
        m.parse(workbook(tmp_path, [row(**changes)]))


@pytest.mark.parametrize('headers', [m.FIELDS + ('name',), m.FIELDS + ('extra',), m.FIELDS[1:]])
def test_headers(tmp_path, headers):
    with pytest.raises(m.ValidationError):
        m.parse(workbook(tmp_path, headers=headers))


@pytest.mark.parametrize('epoch', [None, CALENDAR_MAC_1904])
def test_dates_and_serialization(tmp_path, epoch):
    records = m.parse(workbook(tmp_path, [{}, row(startDate=datetime(2026, 11, 1), endDate=date(2026, 11, 3), entryFee=0, maxNumberOfTeams=12, contactInformation='+41 12345678')], epoch=epoch))
    assert records[0]['_row'] == 3
    data = m.document(records[0], 'organizer')
    assert data['startDate'] == '2026-11-01T00:00:00.000Z'
    assert data['currency'] == 'EUR'
    assert data['signupDeadline'] is None


def test_duplicates(tmp_path):
    with pytest.raises(m.ValidationError, match='duplicate of row 2'):
        m.parse(workbook(tmp_path, [row(), row(name=' ＣＵＰ ', city=' BERN ')]))


def test_size(tmp_path):
    values = [row(name=f'Cup {n}') for n in range(501)]
    with pytest.raises(m.ValidationError, match='Maximum 500'):
        m.parse(workbook(tmp_path, values))
    assert len(m.parse(workbook(tmp_path, values[:500]))) == 500


def args(tmp_path, dry=False):
    return argparse.Namespace(file=workbook(tmp_path), project='demo-import', organizer_id='organizer', dry_run=dry)


def database(existing=()):
    db = MagicMock()
    db.collection.return_value.stream.return_value = existing
    return db


def test_existing_duplicate(tmp_path):
    snapshot = MagicMock(id='existing')
    snapshot.to_dict.return_value = row()
    with pytest.raises(m.ValidationError, match='existing tournament existing'):
        m.run_import(args(tmp_path, True), database([snapshot]))


@pytest.mark.parametrize('answer', ['IMPORT', 'no', EOFError()])
def test_confirmation(tmp_path, monkeypatch, answer):
    db = database()
    monkeypatch.setattr(sys.stdin, 'isatty', lambda: True)
    def prompt(_):
        if isinstance(answer, Exception):
            raise answer
        return answer
    monkeypatch.setattr('builtins.input', prompt)
    assert m.run_import(args(tmp_path), db) == 0
    assert db.batch.return_value.commit.call_count == (1 if answer == 'IMPORT' else 0)
    if answer == 'IMPORT':
        assert db.collection.return_value.stream.call_count == 2
        assert db.batch.return_value.create.call_count == 1


def test_dry_and_noninteractive(tmp_path, monkeypatch):
    db = database()
    assert m.run_import(args(tmp_path, True), db) == 0
    monkeypatch.setattr(sys.stdin, 'isatty', lambda: False)
    assert m.run_import(args(tmp_path), db) == 1
    db.batch.assert_not_called()


def test_invalid_organizer(tmp_path, monkeypatch):
    import firebase_admin.auth as auth
    import firebase_admin
    monkeypatch.setattr(firebase_admin, 'initialize_app', lambda *a, **k: object())
    monkeypatch.setattr('firebase_admin.credentials.ApplicationDefault', lambda: object())
    def missing(*a, **k):
        raise ValueError('Organizer missing')
    monkeypatch.setattr(auth, 'get_user', missing)
    with pytest.raises(ValueError, match='Organizer missing'):
        m.run_import(args(tmp_path, True))


def test_recheck_blocks(tmp_path, monkeypatch):
    db = database()
    snapshot = MagicMock(id='new-match')
    snapshot.to_dict.return_value = row()
    db.collection.return_value.stream.side_effect = [[], [snapshot]]
    monkeypatch.setattr(sys.stdin, 'isatty', lambda: True)
    monkeypatch.setattr('builtins.input', lambda _: 'IMPORT')
    with pytest.raises(m.ValidationError, match='new-match'):
        m.run_import(args(tmp_path), db)
    db.batch.assert_not_called()


@pytest.mark.skipif(not os.environ.get('FIRESTORE_EMULATOR_HOST') or not os.environ.get('FIREBASE_AUTH_EMULATOR_HOST'), reason='Requires Firestore and Auth emulators')
def test_emulator_atomic_import(tmp_path, monkeypatch):
    import uuid
    import firebase_admin
    from firebase_admin import auth, firestore
    from google.auth.credentials import AnonymousCredentials
    from google.api_core.exceptions import AlreadyExists
    project = 'demo-import-' + uuid.uuid4().hex[:8]
    app = firebase_admin.initialize_app(options={'projectId': project}, name=project)
    uid = auth.create_user(uid='organizer', app=app).uid
    assert auth.get_user(uid, app=app).uid == uid
    db = firestore.Client(project=project, credentials=AnonymousCredentials())
    records = m.parse(workbook(tmp_path, [row(), row(name='Second Cup')]))
    docs = [m.document(r, uid) for r in records]
    monkeypatch.setattr(sys.stdin, 'isatty', lambda: True)
    monkeypatch.setattr('builtins.input', lambda _: 'IMPORT')
    import_args = argparse.Namespace(file=tmp_path / 'input.xlsx', project=project, organizer_id=uid, dry_run=False)
    assert m.run_import(import_args, db) == 0
    assert len(list(db.collection('tournaments').stream())) == 2
    with pytest.raises(m.ValidationError):
        m.check_existing(records, db)
    new = m.document(dict(records[0], name='Third Cup'), uid)
    batch = db.batch()
    batch.create(db.collection('tournaments').document(new['id']), new)
    batch.create(db.collection('tournaments').document(docs[0]['id']), docs[0])
    with pytest.raises(AlreadyExists):
        batch.commit()
    assert not db.collection('tournaments').document(new['id']).get().exists
    for data in docs:
        db.collection('tournaments').document(data['id']).delete()
    auth.delete_user(uid, app=app)
    firebase_admin.delete_app(app)
