"""认证模块：登录 / 注销 / 修改密码"""
from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from db import call_proc, execute, query
from decorators import login_required

auth_bp = Blueprint('auth', __name__)


def _parse_roles(roles_str):
    """从 fn_tyh_UserLogin08 返回的逗号分隔角色字符串解析角色ID"""
    if not roles_str:
        return [], []
    role_map = {
        '系统管理员': 1, '人事管理员': 2, '财务管理员': 3,
        '总经理': 4, '审计管理员': 5
    }
    names = [r.strip() for r in roles_str.split(',') if r.strip()]
    ids = [role_map[n] for n in names if n in role_map]
    return ids, names


@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
        return render_template('login.html')

    username = request.form.get('username', '').strip()
    password = request.form.get('password', '')

    if not username or not password:
        flash('请输入用户名和密码', 'warning')
        return render_template('login.html')

    try:
        rows = call_proc('fn_tyh_UserLogin08', [username, password])
        if rows:
            success, message, eno, roles_str = rows[0]
        else:
            flash('登录失败，请重试', 'danger')
            return render_template('login.html')
    except Exception as e:
        flash(f'登录出错：{e}', 'danger')
        return render_template('login.html')

    if success:
        role_ids, role_names = _parse_roles(roles_str)
        session.permanent = True
        session['username'] = username
        session['eno'] = eno
        session['role_ids'] = role_ids
        session['role_names'] = role_names
        flash(f'欢迎回来，{username}！角色：{roles_str}', 'success')
        return redirect(url_for('dashboard.index'))
    else:
        flash(message, 'danger')
        return render_template('login.html', username=username)


@auth_bp.route('/logout')
def logout():
    session.clear()
    flash('已安全退出', 'info')
    return redirect(url_for('auth.login'))


@auth_bp.route('/change-password', methods=['GET', 'POST'])
@login_required
def change_password():
    if request.method == 'GET':
        return render_template('change_password.html')

    old_pwd = request.form.get('old_password', '')
    new_pwd = request.form.get('new_password', '')
    confirm_pwd = request.form.get('confirm_password', '')

    if new_pwd != confirm_pwd:
        flash('两次输入的新密码不一致', 'warning')
        return render_template('change_password.html')

    if len(new_pwd) < 8:
        flash('新密码长度至少8位', 'warning')
        return render_template('change_password.html')

    username = session['username']

    # 验证旧密码
    try:
        rows = call_proc('fn_tyh_UserLogin08', [username, old_pwd])
        if not rows or not rows[0][0]:
            flash('原密码错误', 'danger')
            return render_template('change_password.html')
    except Exception as e:
        flash(f'验证失败：{e}', 'danger')
        return render_template('change_password.html')

    # 更新密码
    try:
        hashed = query("SELECT MD5(%s) AS h", [new_pwd])
        new_hash = hashed[0][0]
        execute(
            "UPDATE Tongyh_Uspa08 SET tyh_Encryptedpassword08 = %s WHERE tyh_Username08 = %s",
            [new_hash, username]
        )
        flash('密码修改成功', 'success')
        return redirect(url_for('dashboard.index'))
    except Exception as e:
        flash(f'修改失败：{e}', 'danger')
        return render_template('change_password.html')
