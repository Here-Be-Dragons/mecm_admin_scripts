# mecm_admin_scripts

Administrative Scripts for use inside of the MECM tool

## Usage

1. Place PowerShell (`.ps1` only) scripts in the `mecm_scripts/` folder and commit to a development branch.
1. GitLab CI will pick up the changes when a merge to master occurs via PR, and:
   1. Upload them.
   1. Auto-approve them.

In the MECM interface, any scripts that are managed by this process will have "Approved by GitLab-CI" in the *Approval Notes* field.

## Automatic Naming

The upload scripts attempts naming the script in MECM in two ways:

1. It looks for a line in the script that matches the RegEx `'^\s*#*\s*Function:\s*(.*)$'`, such as:

   ```
       Function: Disable IPV6 On All Network Adapters
   ```
   This would upload a script named "Disable IPV6 On All Network Adapters"
1. If the above step fails to match, the script is named using the Filename.

## Limitations

* Only `.ps1` files are supported
* Files that are renamed or deleted in the repository are not cleaned up in MECM.  These files will be left in MECM and no longer managed by GitLab.