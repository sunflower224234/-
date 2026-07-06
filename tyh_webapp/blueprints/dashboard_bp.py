"""仪表盘首页"""
from flask import Blueprint, render_template, session, request
from db import query
from decorators import login_required
from datetime import datetime

dashboard_bp = Blueprint('dashboard', __name__)


def is_regular_employee():
    """是否普通员工（有关联eno但无管理角色）"""
    role_ids = session.get('role_ids', [])
    return session.get('eno') and not any(r in role_ids for r in [1, 2, 3, 4, 5])


@dashboard_bp.route('/')
@login_required
def index():
    now = datetime.now()

    if is_regular_employee():
        return _regular_dashboard(now)
    else:
        return _manager_dashboard(now)


def _manager_dashboard(now):
    """管理员/总经理/人事/财务等角色看到的全公司仪表盘"""
    emp_count = query("SELECT COUNT(*) FROM Tongyh_Emp08")[0][0]
    dept_count = query("SELECT COUNT(*) FROM Tongyh_Depts08")[0][0]

    available_months = query("""
        SELECT tyh_Year08, tyh_Months08
        FROM Tongyh_Gz08
        GROUP BY tyh_Year08, tyh_Months08
        ORDER BY tyh_Year08 DESC, tyh_Months08 DESC
    """)

    if available_months:
        latest = available_months[0]
        default_year, default_month = latest[0], latest[1]
    else:
        default_year, default_month = now.year, now.month

    year = request.args.get('year', default_year, type=int)
    month = request.args.get('month', default_month, type=int)

    month_count = query(
        "SELECT COUNT(DISTINCT tyh_Eno08) FROM Tongyh_Gz08 WHERE tyh_Year08=%s AND tyh_Months08=%s",
        [year, month]
    )[0][0]

    month_total = query(
        "SELECT COALESCE(SUM(tyh_Sf08), 0) FROM Tongyh_Gz08 WHERE tyh_Year08=%s AND tyh_Months08=%s",
        [year, month]
    )[0][0]

    dept_stats_rows = query("""
        SELECT tyh_Dname08, tyh_EmpCount08, tyh_TotalNet08, tyh_AvgNet08,
               tyh_MaxNet08, tyh_MinNet08, tyh_TotalTax08
        FROM v_tyh_DeptSalaryStats08
        WHERE tyh_Year08 = %s AND tyh_Months08 = %s
        ORDER BY tyh_TotalNet08 DESC
    """, [year, month])

    dept_stats = []
    for row in dept_stats_rows:
        net = float(row[2] or 0)
        tax = float(row[6] or 0)
        dept_stats.append({
            'dname': row[0], 'empcount': row[1],
            'totalnet': net, 'avgnet': float(row[3] or 0),
            'maxnet': float(row[4] or 0), 'minnet': float(row[5] or 0),
            'totaltax': tax, 'gross': net + tax
        })

    recent_logs = query("""
        SELECT tyh_Username08, tyh_Operation08, tyh_Details08,
               TO_CHAR(tyh_Timestamp08, 'MM-DD HH24:MI') AS ts
        FROM v_tyh_AuditLog08
        LIMIT 10
    """)

    return render_template('dashboard.html',
        is_regular=False,
        emp_count=emp_count, dept_count=dept_count,
        month_count=month_count, month_total=month_total or 0,
        dept_stats=dept_stats, recent_logs=recent_logs,
        now=now, year=year, month=month,
        available_months=available_months
    )


def _regular_dashboard(now):
    """普通员工看到的个人仪表盘"""
    eno = session.get('eno')

    # 个人信息
    emp = query("""
        SELECT e.tyh_Eno08, e.tyh_Ename08, e.tyh_Position08, e.tyh_Level08,
               d.tyh_Dname08
        FROM Tongyh_Emp08 e
        LEFT JOIN Tongyh_Depts08 d ON e.tyh_Dno08 = d.tyh_Dno08
        WHERE e.tyh_Eno08 = %s
    """, [eno])

    # 最新月份工资
    latest_salary = query("""
        SELECT tyh_Year08, tyh_Months08, tyh_Sf08, tyh_Ks08, tyh_ExtraCost08
        FROM Tongyh_Gz08
        WHERE tyh_Eno08 = %s
        ORDER BY tyh_Year08 DESC, tyh_Months08 DESC
        LIMIT 1
    """, [eno])

    # 近12个月工资历史
    salary_hist = query("""
        SELECT tyh_Year08, tyh_Months08, tyh_Sf08, tyh_Ks08, tyh_ExtraCost08
        FROM Tongyh_Gz08
        WHERE tyh_Eno08 = %s
        ORDER BY tyh_Year08 DESC, tyh_Months08 DESC
        LIMIT 12
    """, [eno])

    # 当年专项扣除汇总
    special_total = query("""
        SELECT COALESCE(tyh_ChildEdu08,0) + COALESCE(tyh_ContinueEdu08,0)
             + COALESCE(tyh_MedicalTreat08,0) + COALESCE(tyh_HouseLoans08,0)
             + COALESCE(tyh_HouseRent08,0) + COALESCE(tyh_SupportElderly08,0)
             + COALESCE(tyh_ChildCare08,0)
        FROM Tongyh_Special08
        WHERE tyh_Eno08 = %s AND tyh_Year08 = %s
    """, [eno, now.year])

    # 当前月考勤
    current_att = query("""
        SELECT tyh_Wday08, tyh_Sj08, tyh_Cd08, tyh_Jiaban08, tyh_Allday08,
               tyh_AbsenceDeduction08, tyh_OtherDeduction08
        FROM Tongyh_SalaryDetail08
        WHERE tyh_Eno08 = %s AND tyh_Year08 = %s AND tyh_Months08 = %s
    """, [eno, now.year, now.month])

    return render_template('dashboard.html',
        is_regular=True,
        emp=emp[0] if emp else None,
        latest_salary=latest_salary[0] if latest_salary else None,
        salary_hist=salary_hist,
        special_total=special_total[0][0] if special_total else 0,
        current_att=current_att[0] if current_att else None,
        now=now
    )
