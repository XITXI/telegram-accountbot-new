#!/bin/bash

# 阿里云余额监控机器人简化部署脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Docker环境
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi

    log_info "Docker环境检查通过"
}

# 配置环境变量
setup_config() {
    if [[ ! -f ".env" ]]; then
        cp .env.example .env
        log_info "已创建.env配置文件"
        log_warn "请编辑.env文件，配置必要的参数："
        echo "  - BOT_TOKEN: Telegram Bot Token"
        echo "  - WEBHOOK_URL: Webhook URL"
        echo "  - ADMIN_CHAT_IDS: 管理员Telegram用户ID"
        echo ""
        read -p "按回车键继续..."
    fi
}

# 部署应用
deploy() {
    log_info "开始部署..."

    # 创建数据目录
    mkdir -p data logs

    # 停止旧容器
    docker-compose down 2>/dev/null || true

    # 构建并启动
    docker-compose build
    docker-compose up -d

    log_info "部署完成！"

    # 等待服务启动
    sleep 5

    # 检查状态
    if docker-compose ps | grep -q "Up"; then
        log_info "服务启动成功"
        log_info "访问 http://localhost:5000/health 检查服务状态"
        log_info "查看日志: docker-compose logs -f"
    else
        log_error "服务启动失败，请查看日志: docker-compose logs"
    fi
}

# 主函数
main() {
    log_info "阿里云余额监控机器人部署脚本"

    check_docker
    setup_config
    deploy
}

main "$@"


