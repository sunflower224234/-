"""审计日志模块"""
from flask import Blueprint, render_template, request, flash
from db import query
from decorators import login_required, role_required

log_bp = Blueprint('log', __name__)


@log_bp.route('/')
@login_required
@role_required([1, 5])
def list():
    page = request.args.get('page', 1, type=int)
    op_type = request.args.get('op_type', '').strip()
    per_page = 20
    offset = (page - 1) * per_page

    sql = """
        SELECT tyh_LogId08, tyh_Username08, tyh_Operation08, tyh_Details08,
               TO_CHAR(tyh_Timestamp08, 'YYYY-MM-DD HH24:MI:SS') AS ts
        FROM Tongyh_OperationLogs08
    """
    count_sql = "SELECT COUNT(*) FROM Tongyh_OperationLogs08"
    params = []
    count_params = []

    if op_type:
        sql += " WHERE tyh_Operation08 LIKE %s"
        count_sql += " WHERE tyh_Operation08 LIKE %s"
        params.append(f'%{op_type}%')
        count_params.append(f'%{op_type}%')

    sql += " ORDER BY tyh_Timestamp08 DESC"
    sql += f" LIMIT {per_page} OFFSET {offset}"

    logs = query(sql, params)
    total = query(count_sql, count_params)[0][0]
    total_pages = max(1, (total + per_page - 1) // per_page)

    # 操作类型列表（用于筛选下拉）
    op_types = query("""
        SELECT DISTINCT tyh_Operation08 FROM Tongyh_OperationLogs08
        ORDER BY tyh_Operation08
    """)

    return render_template('log/list.html', logs=logs, page=page, total_pages=total_pages,
        total=total, op_type=op_type, op_types=op_types)
