#!/usr/bin/env python3
# apply-chromium-patches.py - Apply patches for chromium based on versions.

import argparse
import glob
import logging
import os
import subprocess

PATCHES_DIR = os.path.join(os.path.dirname(__file__))
logger = logging.getLogger(__name__)

def execute_patch(patch_file, dry_run, verbose=0, revert=False):
  patch_args = ["patch"]
  suffix_args = ["-p1", "-i", patch_file]
  additional_args = []
  if revert:
    patch_args += ["-R"]
  if verbose < 1:
    additional_args += ["-s"]
  try:
    subprocess.check_call(
      patch_args + additional_args + ["--dry-run"] + suffix_args,
      stdin=subprocess.DEVNULL
    )
  except:
    return False
  if dry_run: return True
  subprocess.check_call(patch_args + ["-s"] + suffix_args)
  return True

def execute(args, p):
  is_revert_mode = args.revert
  is_dry_run_mode = args.dry_run
  verbose_level = args.verbose
  patches = sorted(glob.glob(os.path.join(PATCHES_DIR, "*.patch")))
  applied_patches = []
  need_revert = False
  for patch_path in patches:
    ope_str = "revert" if is_revert_mode else "apply"
    patch_name = os.path.basename(patch_path)
    logger.info("%sing %s...", ope_str.capitalize(), patch_name)
    if not execute_patch(patch_path, is_dry_run_mode, verbose_level, is_revert_mode):
      need_revert = True
      logger.error("Failed to apply %s", patch_path)
      break
    else:
      applied_patches.append(patch_path)
  if need_revert and not is_dry_run_mode:
    ope_str = "re-apply" if is_revert_mode else "revert"
    logger.info("%sing patches due to previous error...", ope_str.capitalize())
    for patch_path in applied_patches[::-1]:
      patch_name = os.path.basename(patch_path)
      logger.info("%sing %s...", ope_str.capitalize(), patch_name)
      execute_patch(os.path.join(PATCHES_DIR, patch_path), is_dry_run_mode, verbose_level, not is_revert_mode)
    exit(1)

def main():
  p = argparse.ArgumentParser(description="Apply/Revert patches for chromium based applications.")
  p.add_argument(
    "-v",
    "--verbose",
    action="count",
    dest="verbose",
    default=0,
    help="Give more output. Option is additive",
  )
  p.add_argument(
    "-R",
    "--revert",
    action="store_true",
    dest="revert",
    default=False,
    help="Set to revert mode.",
  )
  p.add_argument(
    "--dry-run",
    action="store_true",
    dest="dry_run",
    default=False,
    help="Set to dry-run mode.",
  )
  p.add_argument(
    "-C",
    "--chdir",
    action="store",
    dest="workdir",
    default=None,
    help="Change workdir.",
  )
  args = p.parse_args()
  logging.disable(logging.NOTSET)
  if args.verbose >= 1:
    logging.basicConfig(level=logging.DEBUG)
  else:
    logging.basicConfig(level=logging.INFO)
  if args.workdir:
    os.chdir(args.workdir)
  execute(args, p)

if __name__ == '__main__':
  main()
