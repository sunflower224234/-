"""部门管理模块"""
from flask import Blueprint, render_template, request, redirect, url_for, flash
from db import query, execute
from decorators import login_required, role_required

department_bp = Blueprint('department', __name__)


@department_bp.route('/')
@login_required
@role_required([1, 2, 4])
def list():
    departments = query("""
        SELECT d.tyh_Dno08, d.tyh_Dname08, d.tyh_Downer08,
               COUNT(e.tyh_Eno08) AS emp_count
        FROM Tongyh_Depts08 d
        LEFT JOIN Tongyh_Emp08 e ON d.tyh_Dno08 = e.tyh_Dno08
        GROUP BY d.tyh_Dno08, d.tyh_Dname08, d.tyh_Downer08
        ORDER BY d.tyh_Dno08
    """)
    return render_template('department/list.html', departments=departments)


@department_bp.route('/create', methods=['GET', 'POST'])
@login_required
@role_required([1])
def create():
    if request.method == 'GET':
        return render_template('department/form.html', dept=None)
    try:
        execute("INSERT INTO Tongyh_Depts08 (tyh_Dno08, tyh_Dname08, tyh_Downer08) VALUES (%s, %s, %s)",
                [request.form['dno'], request.form['dname'], request.form['downer']])
        flash(f'部门 {request.form["dname"]} 创建成功', 'success')
        return redirect(url_for('department.list'))
    except Exception as e:
        flash(f'创建失败：{e}', 'danger')
        return render_template('department/form.html', dept={
            'dno': request.form['dno'], 'dname': request.form['dname'], 'downer': request.form['downer']
        })


@department_bp.route('/<dno>/edit', methods=['GET', 'POST'])
@login_required
@role_required([1])
def edit(dno):
    if request.method == 'GET':
        rows = query("SELECT * FROM Tongyh_Depts08 WHERE tyh_Dno08 = %s", [dno])
        if not rows:
            flash('部门不存在', 'danger')
            return redirect(url_for('department.list'))
        dept = dict(zip(['dno', 'dname', 'downer'], rows[0]))
        return render_template('department/form.html', dept=dept)
    try:
        execute("UPDATE Tongyh_Depts08 SET tyh_Dname08=%s, tyh_Downer08=%s WHERE tyh_Dno08=%s",
                [request.form['dname'], request.form['downer'], dno])
        flash(f'部门 {request.form["dname"]} 修改成功', 'success')
        return redirect(url_for('department.list'))
    except Exception as e:
        flash(f'修改失败：{e}', 'danger')
        return render_template('department/form.html', dept={'dno': dno, 'dname': request.form['dname'], 'downer': request.form['downer']})


@department_bp.route('/<dno>/delete', methods=['POST'])
@login_required
@role_required([1])
def delete(dno):
    try:
        execute("DELETE FROM Tongyh_Depts08 WHERE tyh_Dno08 = %s", [dno])
        flash(f'部门 {dno} 已删除', 'success')
    except Exception as e:
        flash(f'删除失败（可能有员工关联此部门）：{e}', 'danger')
    return redirect(url_for('department.list'))
