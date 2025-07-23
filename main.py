#!/usr/bin/env python3
"""
Orchestra API - FastAPI-based REST API for managing RStudio workshops.

This API provides a user-friendly interface for creating, monitoring, and managing
workshops through the Orchestra Operator's Workshop CRDs.
"""

import logging
from datetime import datetime
from contextlib import asynccontextmanager

from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

from api.routes import workshops, health
from api.core.config import get_settings
from api.core.kubernetes import get_k8s_client


# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    logger.info("Starting Orchestra API...")
    
    # Initialize Kubernetes client
    try:
        k8s_client = get_k8s_client()
        logger.info("Kubernetes client initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Kubernetes client: {e}")
        raise
    
    yield
    
    logger.info("Shutting down Orchestra API...")


# Create FastAPI app
app = FastAPI(
    title="Orchestra API",
    description="REST API for managing RStudio workshops via Orchestra Operator",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",  # React development server
        "http://localhost:5173",  # Vite development server
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5173",
        # Add production frontend URLs here
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router, tags=["health"])
app.include_router(workshops.router, prefix="/workshops", tags=["workshops"])


@app.get("/", response_model=dict)
async def root():
    """Root endpoint with API information."""
    return {
        "name": "Orchestra API",
        "version": "0.1.0",
        "description": "REST API for managing RStudio workshops",
        "docs_url": "/docs",
        "health_url": "/health",
        "timestamp": datetime.utcnow().isoformat()
    }


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler."""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"}
    )


if __name__ == "__main__":
    settings = get_settings()
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level="info"
    )
