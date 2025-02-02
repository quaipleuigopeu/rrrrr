#!/bin/bash

# 强制脚本以root权限运行
if [ "$(id -u)" != "0" ]; then
    echo "错误：必须使用root用户执行此脚本" >&2
    exit 1
fi

# 安装参数
CONDA_DIR="/opt/miniconda3"
ENV_NAME="SpotTrader"
PYTHON_VERSION="3.9"
REQUIREMENTS_DIR="/home/ubuntu/binance_grid_trader"
REQUIREMENTS_FILE="${REQUIREMENTS_DIR}/requirements.txt"

# 步骤1：安装Miniconda
echo "[1/4] 正在安装Miniconda到 ${CONDA_DIR}..."
wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh || exit 1
bash /tmp/miniconda.sh -b -p $CONDA_DIR || exit 1
rm -f /tmp/miniconda.sh

# 步骤2：配置全局自动激活
echo "[2/4] 设置全局环境变量..."
# 创建全局配置文件
cat > /etc/profile.d/conda-init.sh <<EOF
#!/bin/sh
# 加载Conda基础环境
source "${CONDA_DIR}/etc/profile.d/conda.sh"  # 原始conda初始化脚本
# 自动激活指定环境（对所有用户生效）
conda activate ${ENV_NAME}
EOF

# 设置文件权限
chmod 644 /etc/profile.d/conda-init.sh

# 步骤3：创建Conda环境
echo "[3/4] 创建环境 ${ENV_NAME}..."
export PATH="${CONDA_DIR}/bin:$PATH"  # 临时添加PATH
conda create -n $ENV_NAME python=$PYTHON_VERSION -y || exit 1

# 步骤4：创建requirements.txt文件并安装依赖
echo "[4/4] 确认requirements.txt文件存在并安装项目依赖..."

# 检查目录是否存在，如果不存在则创建
if [ ! -d "$REQUIREMENTS_DIR" ]; then
    echo "创建目录 ${REQUIREMENTS_DIR}..."
    mkdir -p "$REQUIREMENTS_DIR"
fi

# 检查文件是否存在，如果不存在则创建
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo "创建文件 ${REQUIREMENTS_FILE}..."
    touch "$REQUIREMENTS_FILE"
fi

# 检查文件是否为空，如果为空则写入内容
if [ ! -s "$REQUIREMENTS_FILE" ]; then
    echo "写入依赖到 ${REQUIREMENTS_FILE}..."
    cat > $REQUIREMENTS_FILE <<EOL
certifi==2024.8.30
charset-normalizer==3.4.0
idna==3.10
packaging==24.1
PyMySQL==1.1.1
PyQt5==5.15.11
PyQt5-Qt5==5.15.2
PyQt5_sip==12.15.0
pytz==2024.2
QDarkStyle==3.2.3
QtPy==2.4.1
requests==2.32.3
six==1.13.0
tzlocal==2.1
urllib3==2.2.3
websocket-client==1.8.0
EOL
fi

# 安装依赖
conda run -n $ENV_NAME pip install -r $REQUIREMENTS_FILE || exit 1

echo "安装完成！所有用户下次登录时将自动激活 ${ENV_NAME} 环境"
