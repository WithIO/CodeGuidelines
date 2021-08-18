# Minimal makefile for Sphinx documentation
#

PYTHON_BIN ?= poetry run python

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= $(PYTHON_BIN) -m sphinx
SOURCEDIR     = source
BUILDDIR      = build

format: isort black
	exit 0

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

requirements:
	poetry export -o requirements.txt

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

black:
	$(PYTHON_BIN) -m black --target-version py38 --exclude '/(\.git|\.hg|\.mypy_cache|\.nox|\.tox|\.venv|_build|buck-out|build|dist|node_modules|webpack_bundles)/' .

isort:
	$(PYTHON_BIN) -m isort source
