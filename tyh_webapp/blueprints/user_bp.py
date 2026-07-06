"""用户与角色管理模块"""
from flask import Blueprint, render_template, request, redirect, url_for, flash
from db import query, execute
from decorators import login_required, role_required
from datetime import datetime

user_bp = Blueprint('user', __name__)


@user_bp.route('/')
@login_required
@role_required([1])
def list():
    users = query("""
        SELECT u.tyh_Username08, u.tyh_Eno08, e.tyh_Ename08,
               u.tyh_FailedAttempts08, u.tyh_LockTime08,
               u.tyh_LastPasswordChange08,
               STRING_AGG(r.tyh_RoleName08, ', ' ORDER BY r.tyh_RoleId08) AS roles
        FROM Tongyh_Uspa08 u
        LEFT JOIN Tongyh_Emp08 e ON u.tyh_Eno08 = e.tyh_Eno08
        LEFT JOIN Tongyh_UserRoles08 ur ON u.tyh_Username08 = ur.tyh_Username08
        LEFT JOIN Tongyh_Roles08 r ON ur.tyh_RoleId08 = r.tyh_RoleId08
        GROUP BY u.tyh_Username08, u.tyh_Eno08, e.tyh_Ename08,
                 u.tyh_FailedAttempts08, u.tyh_LockTime08, u.tyh_LastPasswordChange08
        ORDER BY u.tyh_Username08
    """)
    return render_template('user/list.html', users=users, now=datetime.now())


@user_bp.route('/create', methods=['GET', 'POST'])
@login_required
@role_required([1])
def create():
    employees = query("SELECT tyh_Eno08, tyh_Ename08 FROM Tongyh_Emp08 ORDER BY tyh_Dno08")
    roles = query("SELECT tyh_RoleId08, tyh_RoleName08 FROM Tongyh_Roles08 ORDER BY tyh_RoleId08")
    if request.method == 'GET':
        return render_template('user/form.html', employees=employees, roles=roles, user_data=None)

    username = request.form['username'].strip()
    password = request.form['password'].strip()
    eno = request.form.get('eno', '').strip() or None
    role_ids = request.form.getlist('role_ids')

    try:
        # 获取密码哈希
        hash_rows = query("SELECT fn_tyh_HashPwd08(%s)", [password])
        pwd_hash = hash_rows[0][0] if hash_rows else None

        execute("""
            INSERT INTO Tongyh_Uspa08 (tyh_Username08, tyh_Eno08, tyh_Encryptedpassword08,
                tyh_LastPasswordChange08, tyh_FailedAttempts08)
            VALUES (%s, %s, %s, CURRENT_TIMESTAMP, 0)
        """, [username, eno, pwd_hash])

        for rid in role_ids:
            execute("INSERT INTO Tongyh_UserRoles08 (tyh_Username08, tyh_RoleId08) VALUES (%s, %s)",
                    [username, int(rid)])

        flash(f'用户 {username} 创建成功', 'success')
        return redirect(url_for('user.list'))
    except Exception as e:
        flash(f'创建失败：{e}', 'danger')
        return render_template('user/form.html', employees=employees, roles=roles, user_data={
            'username': username, 'eno': eno, 'role_ids': role_ids
        })


@user_bp.route('/<username>/edit', methods=['GET', 'POST'])
@login_required
@role_required([1])
def edit(username):
    employees = query("SELECT tyh_Eno08, tyh_Ename08 FROM Tongyh_Emp08 ORDER BY tyh_Dno08")
    roles = query("SELECT tyh_RoleId08, tyh_RoleName08 FROM Tongyh_Roles08 ORDER BY tyh_RoleId08")
    if request.method == 'GET':
        u_rows = query("SELECT * FROM Tongyh_Uspa08 WHERE tyh_Username08 = %s", [username])
        if not u_rows:
            flash('用户不存在', 'danger')
            return redirect(url_for('user.list'))
        # 获取已有角色
        ur_rows = query("SELECT tyh_RoleId08 FROM Tongyh_UserRoles08 WHERE tyh_Username08 = %s", [username])
        current_roles = [r[0] for r in ur_rows]
        user_data = {
            'username': username, 'eno': u_rows[0][1] or '',
            'role_ids': current_roles
        }
        return render_template('user/form.html', employees=employees, roles=roles, user_data=user_data)
    try:
        eno = request.form.get('eno', '').strip() or None
        new_role_ids = [int(r) for r in request.form.getlist('role_ids')]

        execute("UPDATE Tongyh_Uspa08 SET tyh_Eno08=%s WHERE tyh_Username08=%s", [eno, username])
        execute("DELETE FROM Tongyh_UserRoles08 WHERE tyh_Username08=%s", [username])
        for rid in new_role_ids:
            execute("INSERT INTO Tongyh_UserRoles08 (tyh_Username08, tyh_RoleId08) VALUES (%s, %s)",
                    [username, rid])

        flash(f'用户 {username} 修改成功', 'success')
        return redirect(url_for('user.list'))
    except Exception as e:
        flash(f'修改失败：{e}', 'danger')
        return render_template('user/form.html', employees=employees, roles=roles, user_data={
            'username': username, 'eno': request.form.get('eno', ''),
            'role_ids': request.form.getlist('role_ids')
        })


@user_bp.route('/<username>/reset-pwd', methods=['POST'])
@login_required
@role_required([1])
def reset_password(username):
    new_pwd = request.form.get('new_password', 'Abc@12345')
    try:
        hash_rows = query("SELECT fn_tyh_HashPwd08(%s)", [new_pwd])
        pwd_hash = hash_rows[0][0] if hash_rows else None
        execute("""
            UPDATE Tongyh_Uspa08 SET tyh_Encryptedpassword08=%s,
                tyh_LastPasswordChange08=CURRENT_TIMESTAMP, tyh_FailedAttempts08=0
            WHERE tyh_Username08=%s
        """, [pwd_hash, username])
        flash(f'用户 {username} 密码已重置', 'success')
    except Exception as e:
        flash(f'重置失败：{e}', 'danger')
    return redirect(url_for('user.list'))


@user_bp.route('/<username>/toggle-lock', methods=['POST'])
@login_required
@role_required([1])
def toggle_lock(username):
    try:
        # 检查当前状态
        rows = query("SELECT tyh_LockTime08 FROM Tongyh_Uspa08 WHERE tyh_Username08 = %s", [username])
        if rows and rows[0][0]:
            # 已锁定，解锁
            execute("UPDATE Tongyh_Uspa08 SET tyh_LockTime08=NULL, tyh_FailedAttempts08=0 WHERE tyh_Username08=%s",
                    [username])
            flash(f'用户 {username} 已手动解锁', 'success')
        else:
            # 未锁定，手动锁定
            execute("UPDATE Tongyh_Uspa08 SET tyh_LockTime08=CURRENT_TIMESTAMP + INTERVAL '24 hours' WHERE tyh_Username08=%s",
                    [username])
            flash(f'用户 {username} 已手动锁定24小时', 'warning')
    except Exception as e:
        flash(f'操作失败：{e}', 'danger')
    return redirect(url_for('user.list'))
