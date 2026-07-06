"""工资计算与查询模块（核心业务）"""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session, Response
from db import query, call_proc, execute
from decorators import login_required, role_required
from datetime import datetime
import csv
import io

salary_bp = Blueprint('salary', __name__)


@salary_bp.route('/')
@login_required
@role_required([1, 3, 4])
def list():
    now = datetime.now()
    year = request.args.get('year', now.year, type=int)
    month = request.args.get('month', now.month, type=int)
    dept = request.args.get('dept', '').strip()

    sql = """
        SELECT g.tyh_Eno08, e.tyh_Ename08, d.tyh_Dname08, g.tyh_Position08, g.tyh_Level08,
               g.tyh_Sf08, g.tyh_Ks08, g.tyh_ExtraCost08, g.tyh_Year08, g.tyh_Months08
        FROM Tongyh_Gz08 g
        JOIN Tongyh_Emp08 e ON g.tyh_Eno08 = e.tyh_Eno08
        LEFT JOIN Tongyh_Depts08 d ON g.tyh_Dno08 = d.tyh_Dno08
        WHERE g.tyh_Year08 = %s AND g.tyh_Months08 = %s
    """
    params = [year, month]
    if dept:
        sql += " AND g.tyh_Dno08 = %s"
        params.append(dept)
    sql += " ORDER BY d.tyh_Dno08, g.tyh_Sf08 DESC"

    salaries = query(sql, params)
    departments = query("SELECT tyh_Dno08, tyh_Dname08 FROM Tongyh_Depts08 ORDER BY tyh_Dno08")

    # 汇总
    total_net = sum(s[5] or 0 for s in salaries)
    total_tax = sum(s[6] or 0 for s in salaries)

    return render_template('salary/list.html', salaries=salaries,
        year=year, month=month, dept=dept, departments=departments,
        total_net=total_net, total_tax=total_tax)


@salary_bp.route('/calculate', methods=['GET', 'POST'])
@login_required
@role_required([1, 3])
def calculate():
    now = datetime.now()
    if request.method == 'GET':
        # 获取有考勤但可能未计算的员工列表
        attendance_months = query("""
            SELECT DISTINCT sd.tyh_Year08, sd.tyh_Months08
            FROM Tongyh_SalaryDetail08 sd
            ORDER BY sd.tyh_Year08 DESC, sd.tyh_Months08 DESC
            LIMIT 12
        """)
        employees = query("""
            SELECT tyh_Eno08, tyh_Ename08, tyh_Dno08 FROM Tongyh_Emp08 ORDER BY tyh_Dno08
        """)
        return render_template('salary/calculate.html',
            employees=employees, attendance_months=attendance_months, now=now, results=None)

    # POST: 执行计算
    year = request.form.get('year', type=int)
    month = request.form.get('month', type=int)
    mode = request.form.get('mode', 'all')  # 'all' or 'single'
    eno = request.form.get('eno', '').strip()

    if mode == 'single' and eno:
        emp_list = [eno]
    else:
        rows = query("SELECT tyh_Eno08 FROM Tongyh_Emp08 ORDER BY tyh_Dno08")
        emp_list = [r[0] for r in rows]

    results = []
    success_count = 0
    fail_count = 0

    for e in emp_list:
        try:
            rows = call_proc('fn_tyh_CalcSalary08', [e, year, month])
            if rows:
                ok, msg, gross, tax, spec, net = rows[0]
                emp_name = query("SELECT tyh_Ename08 FROM Tongyh_Emp08 WHERE tyh_Eno08=%s", [e])
                ename = emp_name[0][0] if emp_name else e
                results.append({
                    'eno': e, 'ename': ename,
                    'success': ok, 'message': msg,
                    'gross': gross, 'tax': tax, 'special': spec, 'net': net
                })
                if ok:
                    success_count += 1
                else:
                    fail_count += 1
            else:
                results.append({'eno': e, 'ename': e, 'success': False,
                    'message': '存储过程无返回', 'gross': 0, 'tax': 0, 'special': 0, 'net': 0})
                fail_count += 1
        except Exception as ex:
            results.append({'eno': e, 'ename': e, 'success': False,
                'message': str(ex), 'gross': 0, 'tax': 0, 'special': 0, 'net': 0})
            fail_count += 1

    flash(f'计算完成：成功 {success_count} 人，失败 {fail_count} 人', 'success' if fail_count == 0 else 'warning')

    employees = query("""
        SELECT tyh_Eno08, tyh_Ename08, tyh_Dno08 FROM Tongyh_Emp08 ORDER BY tyh_Dno08
    """)
    attendance_months = query("""
        SELECT DISTINCT sd.tyh_Year08, sd.tyh_Months08
        FROM Tongyh_SalaryDetail08 sd ORDER BY sd.tyh_Year08 DESC, sd.tyh_Months08 DESC LIMIT 12
    """)
    return render_template('salary/calculate.html',
        employees=employees, attendance_months=attendance_months,
        now=now, results=results, result_year=year, result_month=month)


@salary_bp.route('/<eno>/history')
@login_required
def history(eno):
    # 权限检查：管理员/财务/总经理可看任意员工，普通员工只能看自己
    if session.get('eno') != eno:
        if not any(r in session.get('role_ids', []) for r in [1, 3, 4]):
            flash('权限不足，只能查看自己的工资', 'danger')
            return redirect(url_for('dashboard.index'))

    emp = query("SELECT tyh_Ename08 FROM Tongyh_Emp08 WHERE tyh_Eno08 = %s", [eno])
    ename = emp[0][0] if emp else eno

    records = query("""
        SELECT tyh_Year08, tyh_Months08, tyh_Sf08, tyh_Ks08, tyh_ExtraCost08
        FROM Tongyh_Gz08 WHERE tyh_Eno08 = %s
        ORDER BY tyh_Year08 DESC, tyh_Months08 DESC
    """, [eno])

    # 按年份分组
    years_data = {}
    for r in records:
        y = r[0]
        if y not in years_data:
            years_data[y] = []
        years_data[y].append(r)

    return render_template('salary/history.html', eno=eno, ename=ename, years_data=years_data)


@salary_bp.route('/<eno>/export')
@login_required
def export_csv(eno):
    """导出员工工资条为CSV"""
    # 权限检查
    if session.get('eno') != eno:
        if not any(r in session.get('role_ids', []) for r in [1, 3, 4]):
            flash('权限不足', 'danger')
            return redirect(url_for('dashboard.index'))

    emp = query("""
        SELECT e.tyh_Ename08, d.tyh_Dname08
        FROM Tongyh_Emp08 e
        LEFT JOIN Tongyh_Depts08 d ON e.tyh_Dno08 = d.tyh_Dno08
        WHERE e.tyh_Eno08 = %s
    """, [eno])
    ename = emp[0][0] if emp else eno
    dname = emp[0][1] if emp else ''

    records = query("""
        SELECT tyh_Year08, tyh_Months08, tyh_Sf08, tyh_Ks08, tyh_ExtraCost08
        FROM Tongyh_Gz08 WHERE tyh_Eno08 = %s
        ORDER BY tyh_Year08 DESC, tyh_Months08 DESC
    """, [eno])

    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(['员工工资条', '', '', '', ''])
    writer.writerow(['姓名', ename, '部门', dname, '工号', eno])
    writer.writerow([])
    writer.writerow(['年份', '月份', '实发工资(元)', '个税(元)', '应发(元)', '补贴(元)'])

    for r in records:
        year, month, net, tax, extra = r
        gross = (net or 0) + (tax or 0)
        writer.writerow([year, month, f'{net:.2f}', f'{tax:.2f}', f'{gross:.2f}', f'{extra or 0:.2f}'])

    out.seek(0)
    filename = f'Salary_{eno}_{datetime.now().strftime("%Y%m%d")}.csv'
    return Response(
        out.getvalue().encode('utf-8-sig'),
        mimetype='text/csv',
        headers={'Content-Disposition': f'attachment; filename="{filename}"'}
    )
