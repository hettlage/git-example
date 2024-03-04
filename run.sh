#!/bin/bash

set -e

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function install {
    python -m pip install --upgrade pip
    python -m pip install --editable $THIS_DIR/[all]
}

function build {
    clean
    python -m build --sdist --wheel ./
}

function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | cat -n
}

function lint {
    pre-commit run --all-files
}

function lint:ci {
    SKIP=no-commit-to-branch pre-commit run --all-files
}

function test:quick {
  python -m pytest -m "not slow" ${THIS_DIR}/tests \
        --cov ${THIS_DIR}/packaging_demo \
        --cov-report html \
        --cov-report term \
        --cov-report xml \
        --cov-fail-under 50 \
        --junit-xml "${THIS_DIR}/test-reports/report.xml"
}

function test {
    python -m pytest "${*:-$THIS_DIR/test}s" \
        --cov ${THIS_DIR}/packaging_demo \
        --cov-report html \
        --cov-report xml \
        --cov-report term \
        --cov-fail-under 60 \
        --junit-xml "${THIS_DIR}/test-reports/report.xml"
    mv coverage.xml "${THIS_DIR}/test-reports"
    mv htmlcov "${THIS_DIR}/test-reports"
}

function test:ci {
    python -m pip install pytest pytest-cov "${THIS_DIR}/dist/*.whl"

    ls -l

    INSTALLED_PKG_DIR="$(python -c 'import packaging_demo; print(packaging_demo.__path__[0])')"
    python -m pytest "${*:-$THIS_DIR/test}s" \
        --cov $INSTALLED_PKG_DIR \
        --cov-report html \
        --cov-report xml \
        --cov-fail-under 60 \
        --junit-xml "${THIS_DIR}/test-reports/report.xml"
    mv coverage.xml "${THIS_DIR}/test-reports"
    mv htmlcov "${THIS_DIR}/test-reports"
}

function serve-coverage-report {
  python -m http.server --directory "${THIS_DIR}/htmlcov/"
}

function publish:test {
  try-load-dotenv || true
  twine upload ${THIS_DIR}/dist/*\
   --repository=testpypi\
   --username=__token__\
   --password=${TEST_PYPI_TOKEN}
}

function publish:prod {
  try-load-dotenv || true
  twine upload ${THIS_DIR}/dist/*\
   --repository=pypi\
   --username=__token__\
   --password=${PROD_PYPI_TOKEN}
}

function release:test {
  lint
  clean
  build
  publish:test
}

function release:prod {
  release:test
  publish:prod
}

function try-load-dotenv {
    if [ ! -f "$THIS_DIR/.env" ]; then
        echo "no .env file found"
        return 1
    fi

    while read -r line; do
        export "$line"
    done < <(grep -v '^#' "$THIS_DIR/.env" | grep -v '^$')
}

function clean {
    rm -rf dist build coverage.xml test-reports
    find . \
      -type d \
      \( \
        -name "*cache*" \
        -o -name "*.dist-info" \
        -o -name "*.egg-info" \
        -o -name "*htmlcov" \
      \) \
      -not -path "*env/*" \
      -exec rm -r {} + || true

    find . \
      -type f \
      -name "*.pyc" \
      -not -path "*env/*" \
      -exec rm {} +
}


TIMEFORMAT="Task completed in %3lR"
time ${@:-help}
