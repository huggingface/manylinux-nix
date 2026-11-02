#!/bin/sh

# Install and test the example wheels on a manylinux_2_28 system.
#
# Usage: test-wheels.sh WHEEL_DIR
#
# Running locally
#
#   docker run --rm \
#     -v "$PWD/.github/test-wheels.sh:/test-wheels.sh:ro" \
#     -v "$PWD/wheels:/wheels:ro" \
#     almalinux:8 sh /test-wheels.sh /wheels

set -eu

UV_VERSION=0.13.4

wheel_dir=${1:?usage: test-wheels.sh WHEEL_DIR}

libc_version=$(getconf GNU_LIBC_VERSION)
echo "System libc: ${libc_version}"
if [ "${libc_version}" != "glibc 2.28" ]; then
  echo "error: expected glibc 2.28" >&2
  exit 1
fi

dnf install -y --allowerasing curl tar gzip
curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" | UV_NO_MODIFY_PATH=1 sh
export PATH="${HOME}/.local/bin:${PATH}"

run_test() {
  name=$1
  python_version=$2
  shift 2

  wheel=$(echo "${wheel_dir}/${name}"-[0-9]*.whl)
  if [ ! -f "${wheel}" ]; then
    echo "error: no wheel found for ${name} in ${wheel_dir}" >&2
    exit 1
  fi

  echo "::group::${name} (Python ${python_version})"
  venv=$(mktemp -d)/venv
  uv venv --python "${python_version}" "${venv}"
  uv pip install --python "${venv}/bin/python" --no-index "${wheel}"
  "${venv}/bin/python" "$@"
  echo "::endgroup::"
}

# lxml is not an abi3 wheel, test it against the Python version that it was
# built for.
lxml_test='
from lxml import etree

print("libxml2:", etree.LIBXML_VERSION, "libxslt:", etree.LIBXSLT_VERSION)

doc = etree.fromstring("<root><a>1</a><a>2</a></root>")
assert doc.xpath("sum(//a)") == 3

xslt = etree.XSLT(etree.fromstring("""
  <xsl:stylesheet version="1.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text"/>
    <xsl:template match="/root"><xsl:value-of select="count(a)"/></xsl:template>
  </xsl:stylesheet>
"""))
assert str(xslt(doc)) == "2"
'
run_test lxml 3.14 -c "${lxml_test}"

# pycrytodome is an abi3 wheel, test against multiple Python versions.
run_test pycryptodome 3.9 -m Crypto.SelfTest
run_test pycryptodome 3.14 -m Crypto.SelfTest
