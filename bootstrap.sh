#! /bin/sh -e

pushd "/tmp/kitchen/data"
  bash docker-storage-setup-strap.sh
popd

# if we get this far, lets do some tests
# https://github.com/test-kitchen/test-kitchen/issues/331
curl -L https://www.chef.io/chef/install.sh | sudo bash
