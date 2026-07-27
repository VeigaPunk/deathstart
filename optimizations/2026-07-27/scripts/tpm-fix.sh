#!/usr/bin/env bash
set -uo pipefail

echo "== TPM-related state files =="
find /var/lib/systemd /etc/systemd /run/systemd /run/credentials -maxdepth 3 \
  \( -iname "*tpm*" -o -iname "*nvpcr*" -o -iname "*anchor*" -o -iname "*srk*" -o -iname "*pcrlock*" \) 2>/dev/null

echo "== purge runtime + persisted anchors, retry =="
rm -f  /var/lib/systemd/tpm2-srk-public-key.pem /var/lib/systemd/tpm2-srk-public-key.tpm2b_public
rm -rf /var/lib/systemd/nvpcr
find /run/systemd -maxdepth 2 \( -iname "*tpm*" -o -iname "*nvpcr*" \) -exec rm -rf {} + 2>/dev/null
systemctl restart systemd-tpm2-setup-early.service systemd-tpm2-setup.service systemd-pcrproduct.service 2>/dev/null

sleep 1
if systemctl is-failed -q systemd-tpm2-setup.service; then
  echo "== still failing -> staging firmware TPM clear (PPI request 5) =="
  # Confirm the prompt the firmware shows at next reboot. After clear,
  # systemd re-provisions the SRK + NvPCR anchors from scratch at boot.
  if [ -w /sys/class/tpm/tpm0/ppi/request ]; then
    echo 5 > /sys/class/tpm/tpm0/ppi/request
    echo "PPI clear staged: $(cat /sys/class/tpm/tpm0/ppi/request)"
  else
    echo "PPI interface unavailable — clear fTPM manually in BIOS (Security -> Trusted Computing)"
  fi
  # leave anchors deleted so first post-clear boot provisions fresh
else
  echo "== recovered without TPM clear =="
fi
systemctl --failed --no-pager | head -8
