from typing import Dict, Optional
from pathlib import Path

import click

BASE_DIRECTORY = str(Path(__file__).parent)

def pre_destroy_check(deployment_directory):
    required_state_files = (
        ".terraform",
        "terraform.tfstate",
    )
    has_all_required_files = all(
        map(
            lambda path: any(deployment_directory.glob(path)),
            required_state_files,
        )
    )
    if not has_all_required_files:
        raise click.UsageError(
            f"""
            Deployment directory is missing some or all of the required state
            files: {required_state_files}. Make sure that you actually have a
            project deployed and that you are in its correct directory."""
        )
