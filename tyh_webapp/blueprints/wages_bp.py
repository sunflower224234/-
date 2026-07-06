"""工资标准管理模块"""
from flask import Blueprint, render_template, request, redirect, url_for, flash
from db import query, execute
from decorators import login_required, role_required

wages_bp = Blueprint('wages', __name__)


@wages_bp.route('/')
@login_required
@role_required([1, 3, 4])
def list():
    wages = query("""
        SELECT w.*, d.tyh_Dname08
        FROM Tongyh_Wages08 w
        LEFT JOIN Tongyh_Depts08 d ON w.tyh_Dno08 = d.tyh_Dno08
        ORDER BY w.tyh_Dno08, w.tyh_Level08 DESC
    """)
    return render_template('wages/list.html', wages=wages)


@wages_bp.route('/create', methods=['GET', 'POST'])
@login_required
@role_required([1, 3])
def create():
    departments = query("SELECT tyh_Dno08, tyh_Dname08 FROM Tongyh_Depts08 ORDER BY tyh_Dno08")
    if request.method == 'GET':
        return render_template('wages/form.html', departments=departments, wage=None)
    try:
        execute("""
            INSERT INTO Tongyh_Wages08 (tyh_Dno08, tyh_Position08, tyh_Level08,
                tyh_Basics08, tyh_Extra08, tyh_Gjj08, tyh_Shebao08, tyh_Riceextra08, tyh_Trafficextra08)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """, [request.form['dno'], request.form['position'], request.form['level'],
              request.form['basics'], request.form['extra'], request.form['gjj'],
              request.form['shebao'], request.form['riceextra'], request.form['trafficextra']])
        flash('工资标准创建成功', 'success')
        return redirect(url_for('wages.list'))
    except Exception as e:
        flash(f'创建失败：{e}', 'danger')
        return render_template('wages/form.html', departments=departments, wage=_wage_form_data())


@wages_bp.route('/<dno>/<position>/<level>/edit', methods=['GET', 'POST'])
@login_required
@role_required([1, 3])
def edit(dno, position, level):
    departments = query("SELECT tyh_Dno08, tyh_Dname08 FROM Tongyh_Depts08 ORDER BY tyh_Dno08")
    if request.method == 'GET':
        rows = query(
            "SELECT * FROM Tongyh_Wages08 WHERE tyh_Dno08=%s AND tyh_Position08=%s AND tyh_Level08=%s",
            [dno, position, level])
        if not rows:
            flash('工资标准不存在', 'danger')
            return redirect(url_for('wages.list'))
        cols = ['dno', 'position', 'level', 'basics', 'extra', 'gjj', 'shebao', 'riceextra', 'trafficextra']
        wage = dict(zip(cols, rows[0]))
        return render_template('wages/form.html', departments=departments, wage=wage)
    try:
        execute("""
            UPDATE Tongyh_Wages08 SET tyh_Basics08=%s, tyh_Extra08=%s, tyh_Gjj08=%s,
                tyh_Shebao08=%s, tyh_Riceextra08=%s, tyh_Trafficextra08=%s
            WHERE tyh_Dno08=%s AND tyh_Position08=%s AND tyh_Level08=%s
        """, [request.form['basics'], request.form['extra'], request.form['gjj'],
              request.form['shebao'], request.form['riceextra'], request.form['trafficextra'],
              dno, position, level])
        flash('工资标准修改成功', 'success')
        return redirect(url_for('wages.list'))
    except Exception as e:
        flash(f'修改失败：{e}', 'danger')
        return render_template('wages/form.html', departments=departments, wage=_wage_form_data())


@wages_bp.route('/<dno>/<position>/<level>/delete', methods=['POST'])
@login_required
@role_required([1])
def delete(dno, position, level):
    try:
        execute("DELETE FROM Tongyh_Wages08 WHERE tyh_Dno08=%s AND tyh_Position08=%s AND tyh_Level08=%s",
                [dno, position, level])
        flash('工资标准已删除', 'success')
    except Exception as e:
        flash(f'删除失败：{e}', 'danger')
    return redirect(url_for('wages.list'))


def _wage_form_data():
    return {
        'dno': request.form.get('dno', ''), 'position': request.form.get('position', ''),
        'level': request.form.get('level', ''), 'basics': request.form.get('basics', '0'),
        'extra': request.form.get('extra', '0'), 'gjj': request.form.get('gjj', '0'),
        'shebao': request.form.get('shebao', '0'), 'riceextra': request.form.get('riceextra', '0'),
        'trafficextra': request.form.get('trafficextra', '0')
    }
