"""Entry point for training. Replace stub with project-specific logic."""

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--run_name", type=str, default=None)
    args = parser.parse_args()

    print(f"[train] config: {args.config}")
    # TODO: load config, build model, train, log to wandb


if __name__ == "__main__":
    main()
