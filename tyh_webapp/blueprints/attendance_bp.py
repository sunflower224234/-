"""考勤明细管理模块"""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from db import query, execute
from decorators import login_required, role_required
from datetime import datetime

attendance_bp = Blueprint('attendance', __name__)


@attendance_bp.route('/my')
@login_required
def my_attendance():
    """普通员工查看自己的考勤记录"""
    eno = session.get('eno')
    if not eno:
        flash('未关联员工信息', 'danger')
        return redirect(url_for('dashboard.index'))

    year = request.args.get('year', datetime.now().year, type=int)
    records = query("""
        SELECT sd.*, e.tyh_Ename08, d.tyh_Dname08
        FROM Tongyh_SalaryDetail08 sd
        JOIN Tongyh_Emp08 e ON sd.tyh_Eno08 = e.tyh_Eno08
        LEFT JOIN Tongyh_Depts08 d ON e.tyh_Dno08 = d.tyh_Dno08
        WHERE sd.tyh_Eno08 = %s AND sd.tyh_Year08 = %s
        ORDER BY sd.tyh_Months08
    """, [eno, year])

    return render_template('attendance/my.html', records=records, year=year, eno=eno)


@attendance_bp.route('/')
@login_required
@role_required([1, 2, 3])
def list():
    now = datetime.now()
    year = request.args.get('year', now.year, type=int)
    month = request.args.get('month', now.month, type=int)

    records = query("""
        SELECT sd.*, e.tyh_Ename08, d.tyh_Dname08
        FROM Tongyh_SalaryDetail08 sd
        JOIN Tongyh_Emp08 e ON sd.tyh_Eno08 = e.tyh_Eno08
        LEFT JOIN Tongyh_Depts08 d ON e.tyh_Dno08 = d.tyh_Dno08
        WHERE sd.tyh_Year08 = %s AND sd.tyh_Months08 = %s
        ORDER BY d.tyh_Dno08, e.tyh_Eno08
    """, [year, month])

    return render_template('attendance/list.html', records=records, year=year, month=month)


@attendance_bp.route('/create', methods=['GET', 'POST'])
@login_required
@role_required([1, 2])
def create():
    employees = query("SELECT tyh_Eno08, tyh_Ename08, tyh_Dno08 FROM Tongyh_Emp08 ORDER BY tyh_Dno08")
    if request.method == 'GET':
        return render_template('attendance/form.html', employees=employees, record=None)
    try:
        execute("""
            INSERT INTO Tongyh_SalaryDetail08 (tyh_Eno08, tyh_Year08, tyh_Months08,
                tyh_Wday08, tyh_Sj08, tyh_Cd08, tyh_Jiaban08, tyh_Allday08,
                tyh_AbsenceDeduction08, tyh_OtherDeduction08)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """, [request.form['eno'], request.form['year'], request.form['month'],
              request.form['wday'], request.form['sj'], request.form['cd'],
              request.form['jiaban'], request.form['allday'],
              request.form['absence'], request.form['other']])
        flash('考勤记录创建成功', 'success')
        return redirect(url_for('attendance.list'))
    except Exception as e:
        flash(f'创建失败：{e}', 'danger')
        return render_template('attendance/form.html', employees=employees, record=_att_form_data())


@attendance_bp.route('/<eno>/<int:year>/<int:month>/edit', methods=['GET', 'POST'])
@login_required
@role_required([1, 2])
def edit(eno, year, month):
    employees = query("SELECT tyh_Eno08, tyh_Ename08, tyh_Dno08 FROM Tongyh_Emp08 ORDER BY tyh_Dno08")
    if request.method == 'GET':
        rows = query(
            "SELECT * FROM Tongyh_SalaryDetail08 WHERE tyh_Eno08=%s AND tyh_Year08=%s AND tyh_Months08=%s",
            [eno, year, month])
        if not rows:
            flash('考勤记录不存在', 'danger')
            return redirect(url_for('attendance.list'))
        cols = ['eno', 'year', 'month', 'wday', 'sj', 'cd', 'jiaban', 'allday', 'absence', 'other']
        record = dict(zip(cols, rows[0]))
        return render_template('attendance/form.html', employees=employees, record=record)
    try:
        execute("""
            UPDATE Tongyh_SalaryDetail08 SET tyh_Wday08=%s, tyh_Sj08=%s, tyh_Cd08=%s,
                tyh_Jiaban08=%s, tyh_Allday08=%s, tyh_AbsenceDeduction08=%s, tyh_OtherDeduction08=%s
            WHERE tyh_Eno08=%s AND tyh_Year08=%s AND tyh_Months08=%s
        """, [request.form['wday'], request.form['sj'], request.form['cd'],
              request.form['jiaban'], request.form['allday'], request.form['absence'],
              request.form['other'], eno, year, month])
        flash('考勤记录修改成功', 'success')
        return redirect(url_for('attendance.list'))
    except Exception as e:
        flash(f'修改失败：{e}', 'danger')
        return render_template('attendance/form.html', employees=employees, record=_att_form_data())


def _att_form_data():
    return {
        'eno': request.form.get('eno', ''), 'year': request.form.get('year', ''),
        'month': request.form.get('month', ''), 'wday': request.form.get('wday', '22'),
        'sj': request.form.get('sj', '22'), 'cd': request.form.get('cd', '0'),
        'jiaban': request.form.get('jiaban', '0'), 'allday': request.form.get('allday', '0'),
        'absence': request.form.get('absence', '0'), 'other': request.form.get('other', '0')
    }
