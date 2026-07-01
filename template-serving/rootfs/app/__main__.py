import os

import uvicorn


def main() -> None:
    host = os.getenv("FRONTEND_HOST", "0.0.0.0")
    port = int(os.getenv("FRONTEND_PORT", "8080"))
    uvicorn.run("app:create_app", host=host, port=port, log_level="info", factory=True)


if __name__ == "__main__":
    main()
