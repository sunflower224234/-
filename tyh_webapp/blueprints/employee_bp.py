"""员工管理模块：列表 / 新增 / 编辑 / 详情 / 家属关系"""
from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from db import query, execute
from decorators import login_required, role_required

employee_bp = Blueprint('employee', __name__)


@employee_bp.route('/')
@login_required
@role_required([1, 2, 4])
def list():
    search = request.args.get('search', '').strip()
    sql = """
        SELECT e.tyh_Eno08, e.tyh_Ename08, e.tyh_Position08, e.tyh_Level08,
               d.tyh_Dname08, vi.tyh_phonemasked08, vi.tyh_email08
        FROM Tongyh_Emp08 e
        LEFT JOIN Tongyh_Depts08 d ON e.tyh_Dno08 = d.tyh_Dno08
        LEFT JOIN v_tyh_EmpInfo08 vi ON e.tyh_Eno08 = vi.tyh_Eno08
    """
    params = []
    if search:
        sql += " WHERE e.tyh_Ename08 LIKE %s OR e.tyh_Eno08 LIKE %s OR d.tyh_Dname08 LIKE %s"
        params = [f'%{search}%', f'%{search}%', f'%{search}%']
    sql += " ORDER BY e.tyh_Dno08, e.tyh_Level08 DESC"
    employees = query(sql, params)
    return render_template('employee/list.html', employees=employees, search=search)


@employee_bp.route('/create', methods=['GET', 'POST'])
@login_required
@role_required([1, 2])
def create():
    departments = query("SELECT tyh_Dno08, tyh_Dname08 FROM Tongyh_Depts08 ORDER BY tyh_Dno08")
    if request.method == 'GET':
        return render_template('employee/form.html', departments=departments, emp=None)

    data = _get_emp_form_data()
    try:
        execute("""
            INSERT INTO Tongyh_Emp08 (tyh_Eno08, tyh_Dno08, tyh_Ename08, tyh_Position08,
                tyh_Level08, tyh_IdCardNumber08, tyh_PhoneNumber08, tyh_Email08, tyh_Address08)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, [data['eno'], data['dno'], data['ename'], data['position'],
              data['level'], data['idcard'], data['phone'], data['email'], data['address']])
        flash(f'员工 {data["ename"]}({data["eno"]}) 创建成功', 'success')
        return redirect(url_for('employee.list'))
    except Exception as e:
        flash(f'创建失败：{e}', 'danger')
        return render_template('employee/form.html', departments=departments, emp=data)


@employee_bp.route('/<eno>/edit', methods=['GET', 'POST'])
@login_required
@role_required([1, 2])
def edit(eno):
    departments = query("SELECT tyh_Dno08, tyh_Dname08 FROM Tongyh_Depts08 ORDER BY tyh_Dno08")
    if request.method == 'GET':
        rows = query("SELECT * FROM Tongyh_Emp08 WHERE tyh_Eno08 = %s", [eno])
        if not rows:
            flash('员工不存在', 'danger')
            return redirect(url_for('employee.list'))
        emp = dict(zip(
            ['eno', 'dno', 'ename', 'position', 'level', 'idcard', 'phone', 'email', 'address'],
            rows[0]
        ))
        return render_template('employee/form.html', departments=departments, emp=emp)

    data = _get_emp_form_data()
    try:
        execute("""
            UPDATE Tongyh_Emp08 SET tyh_Dno08=%s, tyh_Ename08=%s, tyh_Position08=%s,
                tyh_Level08=%s, tyh_IdCardNumber08=%s, tyh_PhoneNumber08=%s,
                tyh_Email08=%s, tyh_Address08=%s
            WHERE tyh_Eno08=%s
        """, [data['dno'], data['ename'], data['position'], data['level'],
              data['idcard'], data['phone'], data['email'], data['address'], eno])
        flash(f'员工 {data["ename"]} 修改成功', 'success')
        return redirect(url_for('employee.list'))
    except Exception as e:
        flash(f'修改失败：{e}', 'danger')
        data['eno'] = eno
        return render_template('employee/form.html', departments=departments, emp=data)


@employee_bp.route('/<eno>/delete', methods=['POST'])
@login_required
@role_required([1])
def delete(eno):
    try:
        execute("DELETE FROM Tongyh_Emp08 WHERE tyh_Eno08 = %s", [eno])
        flash(f'员工 {eno} 已删除', 'success')
    except Exception as e:
        flash(f'删除失败：{e}', 'danger')
    return redirect(url_for('employee.list'))


@employee_bp.route('/<eno>')
@login_required
@role_required([1, 2, 4])
def view(eno):
    rows = query("""
        SELECT e.*, d.tyh_Dname08
        FROM Tongyh_Emp08 e
        LEFT JOIN Tongyh_Depts08 d ON e.tyh_Dno08 = d.tyh_Dno08
        WHERE e.tyh_Eno08 = %s
    """, [eno])
    if not rows:
        flash('员工不存在', 'danger')
        return redirect(url_for('employee.list'))
    emp = dict(zip(
        ['eno', 'dno', 'ename', 'position', 'level', 'idcard', 'phone', 'email', 'address', 'dname'],
        rows[0]
    ))

    # 家属关系
    relations = query("SELECT * FROM Tongyh_Relations08 WHERE tyh_Eno08 = %s", [eno])
    rel_list = [dict(zip(['idcard', 'eno', 'name', 'relationship'], r)) for r in relations]

    # 工资历史
    salary_hist = query("""
        SELECT tyh_Year08, tyh_Months08, tyh_Sf08, tyh_Ks08, tyh_ExtraCost08
        FROM Tongyh_Gz08 WHERE tyh_Eno08 = %s
        ORDER BY tyh_Year08 DESC, tyh_Months08 DESC
        LIMIT 12
    """, [eno])

    # 专项扣除
    specials = query("SELECT * FROM Tongyh_Special08 WHERE tyh_Eno08 = %s ORDER BY tyh_Year08 DESC", [eno])

    return render_template('employee/view.html',
        emp=emp, relations=rel_list, salary_hist=salary_hist, specials=specials)


@employee_bp.route('/<eno>/relations', methods=['GET', 'POST'])
@login_required
@role_required([1, 2])
def manage_relations(eno):
    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'add':
            try:
                execute("""
                    INSERT INTO Tongyh_Relations08 (tyh_IdNumber08, tyh_Eno08, tyh_Jname08, tyh_Relationship08)
                    VALUES (%s, %s, %s, %s)
                """, [request.form['idcard'], eno, request.form['rname'], request.form['relation']])
                flash('家属信息已添加', 'success')
            except Exception as e:
                flash(f'添加失败：{e}', 'danger')
        elif action == 'delete':
            execute("DELETE FROM Tongyh_Relations08 WHERE tyh_IdNumber08=%s AND tyh_Eno08=%s",
                    [request.form['idcard'], eno])
            flash('家属信息已删除', 'success')
        return redirect(url_for('employee.view', eno=eno))
    return redirect(url_for('employee.view', eno=eno))


def _get_emp_form_data():
    return {
        'eno': request.form['eno'].strip(),
        'dno': request.form['dno'].strip(),
        'ename': request.form['ename'].strip(),
        'position': request.form['position'].strip(),
        'level': request.form['level'].strip(),
        'idcard': request.form['idcard'].strip(),
        'phone': request.form['phone'].strip(),
        'email': request.form['email'].strip(),
        'address': request.form['address'].strip(),
    }
