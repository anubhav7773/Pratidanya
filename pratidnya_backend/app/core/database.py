from supabase import create_client, Client
from app.core.config import settings

_supabase_admin_client: Client = None

def get_supabase_admin_client() -> Client:
    """
    Returns singleton Supabase client authenticated with the Service Role Key.
    Used for administrative vector queries and audit log enforcement.
    """
    global _supabase_admin_client
    if _supabase_admin_client is None:
        _supabase_admin_client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY
        )
    return _supabase_admin_client
