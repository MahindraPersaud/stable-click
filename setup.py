from setuptools import setup, find_packages

with open('requirements.txt', 'r') as f:
    install_requires = f.read().splitlines()

setup(
    name="Stable-Click",
    version="0.1",
    install_requires=install_requires,
    entry_points='''
        [console_scripts]
        stable-click=stable_click.cli:main
    ''',
    packages=find_packages(),
)