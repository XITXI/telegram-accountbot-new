# 阿里云余额监控Telegram机器人

一个精简的Telegram机器人，专门用于监控阿里云账户余额。通过GetCreditInfo API获取用户余额信息，支持多账户管理和余额预警。

## 功能特性

- 🔍 **余额查询** - 通过GetCreditInfo API实时获取账户余额
- 👥 **多账户管理** - 支持绑定和管理多个阿里云账户
- ⚠️ **余额预警** - 低余额和余额突降预警
- 🤖 **自动监控** - 定时检查账户余额变化
- 🔐 **安全可靠** - 凭证加密存储，权限控制
- 🐳 **容器化部署** - Docker一键部署

## 快速开始

### 前置要求

- Docker 和 Docker Compose
- Telegram Bot Token
- 管理员Telegram用户ID

### 1. 下载项目

```bash
git clone <your-repo-url>
cd botfather
```

### 2. 配置环境

```bash
# 复制配置模板
cp .env.example .env

# 编辑配置文件
nano .env
```

必须配置：
```env
BOT_TOKEN=your_telegram_bot_token_here
ADMIN_CHAT_IDS=your_telegram_user_id
WEBHOOK_URL=https://your-domain.com  # 可选
```

### 3. 启动服务

```bash
# 使用部署脚本
chmod +x deploy/deploy.sh
./deploy/deploy.sh

# 或手动启动
docker-compose up -d
```

### 4. 验证部署

```bash
# 检查服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 健康检查
curl http://localhost:5000/health
```

## 使用说明

### 初次使用

1. 向机器人发送 `/start` 命令
2. 如果未配置阿里云凭证，按提示输入AK/SK：
   ```
   AK:您的AccessKeyID
   SK:您的AccessKeySecret
   ```
3. 凭证验证成功后即可使用

### 主要命令

- `/start` - 启动机器人并显示菜单
- `/bind_aliyun [UID] [备注] [低余额阈值] [突降阈值]` - 绑定账号
- `/list_aliyun` - 查看绑定列表
- `/aliyun_balance` - 查询所有账号余额
- `/monitor_status` - 查看监控状态
- `/help` - 显示帮助信息

### 绑定账号示例

```
/bind_aliyun 1234567890123456 测试账号 100 50
```

## 项目结构

```
botfather/
├── main.py              # 主程序入口
├── config.py            # 配置管理
├── aliyun_client.py     # 阿里云API客户端（仅GetCreditInfo）
├── bot_handlers.py      # Telegram机器人处理器
├── database.py          # 数据库操作
├── monitor.py           # 监控模块
├── requirements.txt     # Python依赖（精简版）
├── Dockerfile           # Docker配置
├── docker-compose.yml   # Docker Compose配置
├── .env.example         # 环境变量模板
└── deploy/
    ├── deploy.sh        # 部署脚本
    └── README.md        # 详细部署文档
```

## 配置说明

### 环境变量

| 变量名 | 必需 | 说明 | 默认值 |
|--------|------|------|--------|
| BOT_TOKEN | ✅ | Telegram Bot Token | - |
| ADMIN_CHAT_IDS | ✅ | 管理员用户ID（逗号分隔） | - |
| WEBHOOK_URL | ❌ | Webhook URL | - |
| PORT | ❌ | 服务端口 | 5000 |
| CHECK_INTERVAL | ❌ | 监控间隔（秒） | 300 |
| ENABLE_MONITORING | ❌ | 启用自动监控 | true |
| DATABASE_PATH | ❌ | 数据库路径 | bot_data.db |
| ALIYUN_ACCESS_KEY_ID | ❌ | 阿里云AK | - |
| ALIYUN_ACCESS_KEY_SECRET | ❌ | 阿里云SK | - |
| PROXY_URL | ❌ | 代理URL | - |

## 服务管理

### Docker方式

```bash
# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 更新应用
git pull
docker-compose down
docker-compose build
docker-compose up -d
```

### 数据备份

```bash
# 备份数据库
cp data/bot_data.db backup/bot_data_$(date +%Y%m%d).db

# 备份配置
cp .env backup/.env_$(date +%Y%m%d)
```

## 故障排除

### 常见问题

1. **机器人无响应**
   ```bash
   # 检查日志
   docker-compose logs

   # 验证Token
   curl "https://api.telegram.org/bot<TOKEN>/getMe"
   ```

2. **API调用失败**
   ```bash
   # 检查网络连接
   docker-compose exec aliyun-balance-bot ping api.telegram.org

   # 验证阿里云凭证
   # 通过机器人重新设置AK/SK
   ```

3. **容器启动失败**
   ```bash
   # 查看详细日志
   docker-compose logs --tail=50

   # 检查端口占用
   netstat -tlnp | grep :5000
   ```

更多故障排除信息请参考 [deploy/README.md](deploy/README.md)。

## 安全建议

1. 保护 `.env` 文件权限：`chmod 600 .env`
2. 定期备份数据库文件
3. 使用HTTPS和SSL证书
4. 限制管理员用户权限
5. 监控异常访问日志

## 更新日志

### v1.0.0 (精简版)
- 移除冗余API调用，仅保留GetCreditInfo
- 精简依赖包，减少镜像大小
- 优化Docker配置
- 统一配置文件管理
- 简化部署流程

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 支持

- 📖 详细文档：[deploy/README.md](deploy/README.md)
- 🐛 问题反馈：[GitHub Issues]
- ⭐ 如果有用请给个星星！
