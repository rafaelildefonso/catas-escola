import os
import logging
import firebase_admin
from firebase_admin import messaging
from typing import Dict, Optional

from supabase import create_client, Client

logger = logging.getLogger(__name__)

class NotificationService:
    def __init__(self):
        # Configure Supabase client to fetch user devices
        supabase_url: str = os.environ.get("SUPABASE_URL", "")
        supabase_key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
        self.supabase: Client = create_client(supabase_url, supabase_key)

    def _get_user_tokens(self, user_id: str) -> list[str]:
        """Fetch all active FCM tokens for a user from the database."""
        try:
            response = self.supabase.table("user_devices") \
                .select("fcm_token") \
                .eq("user_id", user_id) \
                .eq("active", True) \
                .execute()
            
            return [device["fcm_token"] for device in response.data]
        except Exception as e:
            logger.error(f"Error fetching FCM tokens for user {user_id}: {e}")
            return []

    def send_notification(self, user_id: str, title: str, body: str, data: Optional[Dict[str, str]] = None) -> None:
        """Send an FCM push notification to all active devices of a user."""
        
        # Verify Firebase is initialized
        if not firebase_admin._apps:
            logger.warning("Firebase Admin is not initialized. Cannot send notification.")
            return

        tokens = self._get_user_tokens(user_id)
        
        if not tokens:
            logger.info(f"No active FCM tokens found for user {user_id}. Skipping notification.")
            return
            
        # Ensure data values are strings (FCM requirement)
        fcm_data = {}
        if data:
            fcm_data = {str(k): str(v) for k, v in data.items()}

        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=fcm_data,
            tokens=tokens,
        )

        try:
            response = messaging.send_each_for_multicast(message)
            logger.info(f"Notification sent to {response.success_count} devices. Failed: {response.failure_count}")
            
            # Additional cleanup for invalid tokens could happen here
            # e.g. mapping response.responses and deactivating failed tokens
        except Exception as e:
            logger.error(f"Failed to send FCM notification: {e}")

# Singleton instance for easy import
notification_service = NotificationService()
