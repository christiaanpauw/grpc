/*
 *
 * Copyright 2015 gRPC authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#include <cstdint>
#include <limits>

#include "grpc/grpc.h"
#include "grpc/support/time.h"
#include "timeval.h"

namespace {
constexpr int32_t kNanosPerSecond = 1000000000;
constexpr int32_t kMaxFiniteNanos = kNanosPerSecond - 1;

gpr_timespec ConvertClockType(gpr_timespec t, gpr_clock_type clock_type) {
  return gpr_convert_clock_type(t, clock_type);
}

gpr_timespec MakeInfiniteTimespec(bool future, gpr_clock_type clock_type) {
  gpr_timespec result;
  result.clock_type = clock_type;
  result.tv_sec = future ? std::numeric_limits<int64_t>::max()
                         : std::numeric_limits<int64_t>::min();
  result.tv_nsec = future ? kMaxFiniteNanos : -kMaxFiniteNanos;
  return result;
}
}  // namespace

namespace grpc {
namespace node {

gpr_timespec InfiniteFutureTimespec(gpr_clock_type clock_type) {
  return MakeInfiniteTimespec(true, clock_type);
}

gpr_timespec InfinitePastTimespec(gpr_clock_type clock_type) {
  return MakeInfiniteTimespec(false, clock_type);
}

gpr_timespec MillisecondsToTimespec(double millis) {
  if (millis == std::numeric_limits<double>::infinity()) {
    return InfiniteFutureTimespec(GPR_CLOCK_REALTIME);
  } else if (millis == -std::numeric_limits<double>::infinity()) {
    return InfinitePastTimespec(GPR_CLOCK_REALTIME);
  } else {
    return gpr_time_from_micros(static_cast<int64_t>(millis * 1000),
                                GPR_CLOCK_REALTIME);
  }
}

double TimespecToMilliseconds(gpr_timespec timespec) {
  timespec = ConvertClockType(timespec, GPR_CLOCK_REALTIME);
  if (gpr_time_cmp(timespec, InfiniteFutureTimespec(GPR_CLOCK_REALTIME)) == 0) {
    return std::numeric_limits<double>::infinity();
  } else if (gpr_time_cmp(timespec, InfinitePastTimespec(GPR_CLOCK_REALTIME)) ==
             0) {
    return -std::numeric_limits<double>::infinity();
  } else {
    return (static_cast<double>(timespec.tv_sec) * 1000 +
            static_cast<double>(timespec.tv_nsec) / 1000000);
  }
}

}  // namespace node
}  // namespace grpc
