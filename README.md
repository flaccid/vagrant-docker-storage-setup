# vagrant-docker-storage-setup

Easily run up docker-storage-setup within Vagrant.

With a focus on testing, Test Kitchen is used with Serverspec to help users and contributors of docker-storage-setup.

See the scripts located in the `data` directory which are also portable and can be used on ad-hoc hosts.

## Usage

    $ vagrant up

### Test Kitchen

It's probably better to actually run some integration tests after the virtual machine has been provisioned.

    $ kitchen test

If you would like the machine to not destroy after a successful provision:

    $ kitchen converge

To re-run the tests when the machine is still active:

    $ kitchen verify

### Clearing the attached disk manually

Its important that there is no partition scheme on the disk.
Essentially for a re-test, `/dev/sdb` should not exist in `/proc/partitions`.

You can wipe the partitions with something like:

    # systemctl stop docker
    # lvremove --force dockervg || true && vgchange -a n dockervg vgremove dockervg || true
    # dd if=/dev/zero of=/dev/sdb bs=512 count=1 && (rm -f /dev/sdb1 || true)

### Running the test-kitchen bootstrap manually

If the bootstrap and/or setup of the storage fails, you can login to the
running VM and call the bootstrap script again after ensuring partition wipe:

    $ kitchen login   # this gets you into the VM
    $ sudo /tmp/kitchen/bootstrap.sh


License and Authors
-------------------
- Author: Chris Fordham (<chris@fordham-nagy.id.au>)

```text
Copyright 2011-2015, Chris Fordham

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
