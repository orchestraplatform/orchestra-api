"""Configuration settings for the Orchestra API."""

from functools import lru_cache
from typing import Optional

try:
    from pydantic_settings import BaseSettings
except ImportError:
    # Fallback for when pydantic-settings is not available
    class BaseSettings:
        def __init__(self, **kwargs):
            for key, value in kwargs.items():
                setattr(self, key, value)


class Settings(BaseSettings):
    """Application settings."""
    
    # API settings
    app_name: str = "Orchestra API"
    version: str = "0.1.0"
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 8000
    
    # Kubernetes settings
    kubeconfig_path: Optional[str] = None
    in_cluster: bool = False
    
    # Workshop defaults
    default_workshop_image: str = "rocker/rstudio:latest"
    default_workshop_duration: str = "4h"
    default_cpu_limit: str = "1"
    default_memory_limit: str = "2Gi"
    default_cpu_request: str = "500m"
    default_memory_request: str = "1Gi"
    default_storage_size: str = "10Gi"
    
    # Security
    cors_origins: list = ["*"]
    
    class Config:
        env_prefix = "ORCHESTRA_"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
