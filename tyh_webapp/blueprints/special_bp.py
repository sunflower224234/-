"""专项附加扣除管理模块"""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from db import query, execute
from decorators import login_required, role_required

special_bp = Blueprint('special', __name__)


@special_bp.route('/my')
@login_required
def my_special():
    """普通员工查看自己的专项扣除"""
    eno = session.get('eno')
    if not eno:
        flash('未关联员工信息', 'danger')
        return redirect(url_for('dashboard.index'))

    records = query("""
        SELECT * FROM Tongyh_Special08
        WHERE tyh_Eno08 = %s
        ORDER BY tyh_Year08 DESC
    """, [eno])

    return render_template('special/my.html', records=records, eno=eno)


@special_bp.route('/')
@login_required
@role_required([1, 3])
def list():
    specials = query("""
        SELECT s.*, e.tyh_Ename08
        FROM Tongyh_Special08 s
        JOIN Tongyh_Emp08 e ON s.tyh_Eno08 = e.tyh_Eno08
        ORDER BY s.tyh_Year08 DESC, s.tyh_Eno08
    """)
    return render_template('special/list.html', specials=specials)


@special_bp.route('/create', methods=['GET', 'POST'])
@login_required
@role_required([1, 3])
def create():
    employees = query("SELECT tyh_Eno08, tyh_Ename08 FROM Tongyh_Emp08 ORDER BY tyh_Dno08")
    if request.method == 'GET':
        return render_template('special/form.html', employees=employees, sp=None)
    try:
        execute("""
            INSERT INTO Tongyh_Special08 (tyh_Sno08, tyh_Eno08, tyh_Year08,
                tyh_ChildEdu08, tyh_ContinueEdu08, tyh_MedicalTreat08,
                tyh_HouseLoans08, tyh_HouseRent08, tyh_SupportElderly08, tyh_ChildCare08)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """, [request.form['sno'], request.form['eno'], request.form['year'],
              request.form.get('childedu', 0), request.form.get('continueedu', 0),
              request.form.get('medical', 0), request.form.get('houseloans', 0),
              request.form.get('houserent', 0), request.form.get('elderly', 0),
              request.form.get('childcare', 0)])
        flash('专项扣除记录创建成功', 'success')
        return redirect(url_for('special.list'))
    except Exception as e:
        flash(f'创建失败：{e}', 'danger')
        return render_template('special/form.html', employees=employees, sp=_sp_form_data())


@special_bp.route('/<sno>/edit', methods=['GET', 'POST'])
@login_required
@role_required([1, 3])
def edit(sno):
    employees = query("SELECT tyh_Eno08, tyh_Ename08 FROM Tongyh_Emp08 ORDER BY tyh_Dno08")
    if request.method == 'GET':
        rows = query("SELECT * FROM Tongyh_Special08 WHERE tyh_Sno08 = %s", [sno])
        if not rows:
            flash('扣除记录不存在', 'danger')
            return redirect(url_for('special.list'))
        cols = ['sno', 'eno', 'year', 'childedu', 'continueedu', 'medical',
                'houseloans', 'houserent', 'elderly', 'childcare']
        sp = dict(zip(cols, rows[0]))
        return render_template('special/form.html', employees=employees, sp=sp)
    try:
        execute("""
            UPDATE Tongyh_Special08 SET tyh_Eno08=%s, tyh_Year08=%s,
                tyh_ChildEdu08=%s, tyh_ContinueEdu08=%s, tyh_MedicalTreat08=%s,
                tyh_HouseLoans08=%s, tyh_HouseRent08=%s, tyh_SupportElderly08=%s, tyh_ChildCare08=%s
            WHERE tyh_Sno08=%s
        """, [request.form['eno'], request.form['year'],
              request.form.get('childedu', 0), request.form.get('continueedu', 0),
              request.form.get('medical', 0), request.form.get('houseloans', 0),
              request.form.get('houserent', 0), request.form.get('elderly', 0),
              request.form.get('childcare', 0), sno])
        flash('专项扣除记录修改成功', 'success')
        return redirect(url_for('special.list'))
    except Exception as e:
        flash(f'修改失败：{e}', 'danger')
        return render_template('special/form.html', employees=employees, sp=_sp_form_data())


@special_bp.route('/<sno>/delete', methods=['POST'])
@login_required
@role_required([1])
def delete(sno):
    try:
        execute("DELETE FROM Tongyh_Special08 WHERE tyh_Sno08 = %s", [sno])
        flash('专项扣除记录已删除', 'success')
    except Exception as e:
        flash(f'删除失败：{e}', 'danger')
    return redirect(url_for('special.list'))


def _sp_form_data():
    return {
        'sno': request.form.get('sno', ''), 'eno': request.form.get('eno', ''),
        'year': request.form.get('year', ''), 'childedu': request.form.get('childedu', '0'),
        'continueedu': request.form.get('continueedu', '0'), 'medical': request.form.get('medical', '0'),
        'houseloans': request.form.get('houseloans', '0'), 'houserent': request.form.get('houserent', '0'),
        'elderly': request.form.get('elderly', '0'), 'childcare': request.form.get('childcare', '0')
    }
