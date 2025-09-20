import logging
from typing import Optional, Dict
from alibabacloud_bssopenapi20171214.client import Client as BssOpenApiClient
from alibabacloud_tea_openapi import models as open_api_models
from alibabacloud_bssopenapi20171214 import models as bss_models
from alibabacloud_tea_util import models as util_models
from config import Config

logger = logging.getLogger(__name__)


class AliyunClient:
    def __init__(self):
        self.client = None
        self._init_client()

    def _init_client(self):
        """初始化阿里云客户端"""
        if not Config.ALIYUN_ACCESS_KEY_ID or not Config.ALIYUN_ACCESS_KEY_SECRET:
            logger.warning("阿里云凭证未设置")
            return

        try:
            config = open_api_models.Config(
                access_key_id=Config.ALIYUN_ACCESS_KEY_ID,
                access_key_secret=Config.ALIYUN_ACCESS_KEY_SECRET,
                endpoint="business.aliyuncs.com",
            )
            self.client = BssOpenApiClient(config)
            logger.info("阿里云客户端初始化成功")
        except Exception as e:
            logger.error(f"阿里云客户端初始化失败: {e}")
            self.client = None

    def set_credentials(self, access_key_id: str, access_key_secret: str):
        """设置阿里云凭证并重新初始化客户端"""
        Config.set_aliyun_credentials(access_key_id, access_key_secret)
        self._init_client()

    def get_credit_info(self, uid: str) -> Optional[Dict]:
        """获取指定UID的信用信息

        使用阿里云BSS OpenAPI的GetCreditInfo接口获取真实的信用信息
        """
        if not self.client:
            logger.error("阿里云客户端未初始化")
            return None

        try:
            # 创建GetCreditInfo请求
            if hasattr(bss_models, "GetCreditInfoRequest"):
                request = bss_models.GetCreditInfoRequest()
                request.uid = uid  # 设置要查询的用户UID

                logger.info(f"开始查询UID {uid} 的信用信息")

                runtime = util_models.RuntimeOptions()
                response = self.client.get_credit_info_with_options(request, runtime)

                if response.status_code == 200 and response.body:
                    credit_data = response.body.data

                    result = {
                        "uid": uid,
                        "available_credit": float(credit_data.available_credit or 0),
                        "credit_line": float(credit_data.credit_line or 0),
                        "outstanding_balance": float(
                            credit_data.outstanding_balance or 0
                        ),
                        "zero_credit_shutdown": bool(credit_data.zero_credit_shutdown),
                        "new_buy_status": credit_data.new_buy_status or "Normal",
                        "success": True,
                    }

                    logger.info(
                        f"成功获取UID {uid} 的信用信息: 可用余额={result['available_credit']:.2f}"
                    )
                    return result
                else:
                    logger.error(
                        f"获取UID {uid} 信用信息失败: HTTP {response.status_code}"
                    )
                    return {
                        "uid": uid,
                        "success": False,
                        "error": f"HTTP {response.status_code}",
                    }
            else:
                logger.error("GetCreditInfoRequest类不存在，SDK版本可能不兼容")
                return {
                    "uid": uid,
                    "success": False,
                    "error": "SDK不支持GetCreditInfo接口",
                }

        except Exception as e:
            error_msg = str(e)
            logger.error(f"调用GetCreditInfo API失败 (UID: {uid}): {error_msg}")

            # 根据不同错误类型提供更具体的错误信息
            if "Forbidden" in error_msg or "AccessDenied" in error_msg:
                error_type = "权限不足，请检查AK/SK是否有GetCreditInfo权限"
            elif "InvalidUser" in error_msg or "UserNotFound" in error_msg:
                error_type = "用户UID不存在或无效"
            elif "Throttling" in error_msg:
                error_type = "请求频率过高，请稍后重试"
            elif "SignatureDoesNotMatch" in error_msg:
                error_type = "签名验证失败，请检查AK/SK是否正确"
            else:
                error_type = f"未知错误: {error_msg}"

            return {"uid": uid, "success": False, "error": error_type}

    def test_connection(self) -> bool:
        """测试阿里云连接"""
        if not self.client:
            return False

        # 如果提供了测试UID，则用GetCreditInfo验证
        test_uid = getattr(Config, "ALIYUN_RESELLER_TEST_UID", None)
        if test_uid:
            try:
                result = self.get_credit_info(test_uid)
                if result and result.get("success"):
                    logger.info("凭证验证成功（GetCreditInfo）")
                    return True
                else:
                    logger.error(
                        f"凭证验证失败（GetCreditInfo）: {result.get('error') if result else 'unknown'}"
                    )
                    return False
            except Exception as e:
                logger.error(f"凭证验证异常（GetCreditInfo）: {e}")
                return False

        # 如果没有测试UID，只检查客户端是否初始化成功
        logger.warning("未配置测试UID，无法验证凭证有效性")
        return True

    def is_configured(self) -> bool:
        """检查是否已配置阿里云凭证"""
        return self.client is not None
