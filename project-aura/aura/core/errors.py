"""Custom exceptions used across Project Aura."""


class ProviderNotAvailable(RuntimeError):
    """Raised when a required provider cannot be instantiated."""


class DeviceNotFound(RuntimeError):
    """Raised when expected hardware such as the Kinect sensor is missing."""
