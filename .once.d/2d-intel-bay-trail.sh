#!/usr/bin/env sh

# stability fixes for certain intel bay trail-based CPUs
# see https://en.wikipedia.org/wiki/Silvermont#Erratum
# and list of previously attempted fixes described below
#
# some bay trail devices lose the silicon lottery really hard and exhibit
# stability issues with the i915 display driver with heavy CPU loads and
# hardware accelerated tasks such as video playback
# eg. jumpy pointer, keyboard repeated inputs, system hanging and freezing

# limiting this fix to garbage Atom x5-E8000 (Braswell) for now
! grep -qi 'x5-E8000' < /proc/cpuinfo && exit 0

sudo tee '/etc/modprobe.d/intel-bay-trail.conf' <<- EOF
	# 2020/09: disable panel self-refresh to avoid random system hangs
	#options i915 enable_psr=0

	# 2021/11: disable most forms of processor idling to avoid system hangs at peak load
	#options intel_idle max_cstate=1

	# 2021/11: disable intel_pstate driver to use intel_cpufreq fallback
	blacklist intel_pstate

	# 2022/02: problems seem to be fully resolved with only intel_cpufreq fallback
	# 2023/09: kernel boot params "clocksource=hpet hpet=force" also resolves the issue
EOF
