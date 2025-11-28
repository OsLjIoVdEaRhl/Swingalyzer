# main.py
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
import numpy as np
from scipy.signal import find_peaks, butter, filtfilt
import json
import os
from dotenv import load_dotenv
from openai import OpenAI

# ===== Load API key =====
load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
client = OpenAI(api_key=OPENAI_API_KEY)

# ===== Config =====
LOWPASS_CUTOFF = 20.0
EXPECTED_FS = 208.0
MIN_FS = 30.0
MAX_FS = 1000.0
MIN_SWING_INTERVAL_S = 0.4

# CLUB SPEED / IMPACT CONFIG
RADIUS_M = 1.1  # wrist-to-clubhead approx (meters)
ACCEL_FACTOR = 0.4  # multiplier for accel contribution

GYRO_IS_RADS = False  # True if gyro is already in rad/s

app = FastAPI()

# ===== CORS =====
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== Lowpass filter =====
def lowpass(data, cutoff_hz, fs, order=3):
    nyq = 0.5 * fs
    if cutoff_hz >= nyq or len(data) < (order + 1):
        return data
    b, a = butter(order, cutoff_hz / nyq, btype="low")
    return filtfilt(b, a, data)

# ===== Swing Analysis =====
def analyze_swing(accel_df, gyro_df):
    ts_raw = accel_df["timestamp"].values.astype(np.float64)
    ax = accel_df["x"].values.astype(np.float64)
    ay = accel_df["y"].values.astype(np.float64)
    az = accel_df["z"].values.astype(np.float64)
    n = len(ts_raw)
    if n == 0:
        return []

    # Timestamp normalization & sample rate detection
    candidates = {"seconds": 1.0, "milliseconds": 1e3, "microseconds": 1e6}
    best = None
    best_score = 1e9
    for name, div in candidates.items():
        time_cand = (ts_raw - ts_raw[0]) / div
        if len(time_cand) < 2:
            continue
        dt = np.diff(time_cand)
        if np.any(dt <= 0):
            continue
        fs_cand = 1.0 / np.median(dt)
        valid = (MIN_FS <= fs_cand <= MAX_FS)
        score = abs(fs_cand - EXPECTED_FS) if valid else abs(fs_cand - EXPECTED_FS) + 1e6
        if score < best_score:
            best_score = score
            best = name

    if best is None:
        time = np.arange(n) / EXPECTED_FS
        fs = EXPECTED_FS
    else:
        time = (ts_raw - ts_raw[0]) / candidates[best]
        diffs = np.diff(time) if len(time) > 1 else np.array([1.0/EXPECTED_FS])
        fs = 1.0 / np.median(diffs)

    # accel magnitude and gyro components
    a_res = np.sqrt(ax**2 + ay**2 + az**2)
    gx = gyro_df["x"].values.astype(np.float64)
    gy = gyro_df["y"].values.astype(np.float64)
    gz = gyro_df["z"].values.astype(np.float64)

    if GYRO_IS_RADS:
        gx_rad = gx
        gy_rad = gy
        gz_rad = gz
    else:
        gx_rad = np.deg2rad(gx)
        gy_rad = np.deg2rad(gy)
        gz_rad = np.deg2rad(gz)

    omega_res_rad = np.sqrt(gx_rad**2 + gy_rad**2 + gz_rad**2)

    # Filter signals
    a_filt = lowpass(a_res, LOWPASS_CUTOFF, fs)
    omega_filt = lowpass(omega_res_rad, LOWPASS_CUTOFF, fs)
    gx_filt = lowpass(gx_rad, LOWPASS_CUTOFF, fs)
    gy_filt = lowpass(gy_rad, LOWPASS_CUTOFF, fs)
    gz_filt = lowpass(gz_rad, LOWPASS_CUTOFF, fs)

    # Detect peaks in filtered accel magnitude
    signal_span = np.max(a_filt) - np.median(a_filt)
    prominence = max(0.6 * signal_span, 1e-6)
    distance_samples = max(1, int(MIN_SWING_INTERVAL_S * fs))
    peaks, _ = find_peaks(a_filt, prominence=prominence, distance=distance_samples)

    swings = []
    for i, p in enumerate(peaks):
        peak_val = a_filt[p]
        # find downswing start
        lookback_samples = int(2.0 * fs)
        start_search = max(0, p - lookback_samples)
        baseline = np.median(a_filt[start_search : p + 1])
        thr = baseline + 0.12 * (peak_val - baseline)
        idxs = np.where(a_filt[start_search:p] <= thr)[0]
        downswing_start_idx = (
            start_search + idxs[-1] + 1 if len(idxs) > 0 else max(start_search, p - int(0.5 * fs))
        )

        # find impact index
        lookahead_samples = int(1.0 * fs)
        end_search = min(n - 1, p + lookahead_samples)
        segment_after_peak = a_filt[p : end_search + 1]
        if len(segment_after_peak) > 2:
            impact_rel = np.where(segment_after_peak < 0.8 * peak_val)[0]
            impact_idx = p + impact_rel[0] if len(impact_rel) > 0 else end_search
        else:
            impact_idx = p

        # backswing detection — moved earlier
        prev_boundary = peaks[i - 1] if i > 0 else max(0, p - int(3.0 * fs))
        segment_start = prev_boundary
        segment_end = downswing_start_idx
        if segment_end <= segment_start:
            segment_start = max(0, downswing_start_idx - int(0.5 * fs))
        local_window = a_filt[segment_start : segment_end + 1]

        if len(local_window) > 0:
            min_idx = np.argmin(local_window)
            # Move start ~250ms earlier
            backswing_start_idx = max(segment_start, segment_start + min_idx - int(0.25*fs))
        else:
            backswing_start_idx = max(0, downswing_start_idx - int(0.5 * fs))

        # times
        ts_impact = time[impact_idx]
        ts_downswing_start = time[downswing_start_idx]
        ts_backswing_start = time[backswing_start_idx]

        downswing_time = ts_impact - ts_downswing_start if ts_impact > ts_downswing_start else 0.0
        backswing_time = ts_downswing_start - ts_backswing_start if ts_downswing_start > ts_backswing_start else 0.0
        tempo_ratio = (backswing_time / downswing_time) if downswing_time > 0 else None

        # gyro-derived max angular velocity (rad/s)
        max_omega_rad = float(np.max(omega_filt[downswing_start_idx:impact_idx])) if impact_idx > downswing_start_idx else float(np.max(omega_filt))

        # velocity contribution from accel
        v_from_accel = float(peak_val) * float(downswing_time) * ACCEL_FACTOR if downswing_time > 0 else 0.0
        v_from_gyro = max_omega_rad * RADIUS_M
        club_speed_est = v_from_gyro + v_from_accel

        # Impact orientation
        impact_delta_angle_deg = 0.0
        if impact_idx > downswing_start_idx:
            t_seg = time[downswing_start_idx : impact_idx + 1]
            gz_seg = gz_filt[downswing_start_idx : impact_idx + 1]
            delta_rad = float(np.trapz(gz_seg, t_seg))
            impact_delta_angle_deg = np.degrees(delta_rad)
        if impact_delta_angle_deg > 10.0:
            impact_orientation = "open"
        elif impact_delta_angle_deg < -10.0:
            impact_orientation = "closed"
        else:
            impact_orientation = "good"

        swings.append({
            "swing_number": int(i + 1),
            "backswing_time": round(float(backswing_time), 3),
            "downswing_time": round(float(downswing_time), 3),
            "tempo_ratio": round(float(tempo_ratio), 2) if tempo_ratio is not None else None,
            "max_accel": round(float(peak_val), 2),
            "max_gyro_rad_s": round(float(max_omega_rad), 3),
            "club_speed_est": round(float(club_speed_est), 2),
            "impact_delta_angle": round(float(impact_delta_angle_deg), 2),
            "impact_orientation": impact_orientation
        })

    return swings

# ===== GPT Feedback =====
def get_feedback_from_gpt(swings_json):
    try:
        prompt = f"Analyze these golf swings. Write a bulletlist, 3 subheaders: Cause - Problem - Solution. Each part should not be more then 3 lines of text:\n{json.dumps(swings_json, indent=2)}"
        response = client.chat.completions.create(
            model="gpt-5",
            messages=[{"role": "user", "content": prompt}],
            temperature=1,
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"GPT feedback failed: {str(e)}"

# ===== API Endpoint =====
@app.post("/analyze_swing")
async def analyze_swing_endpoint(acc_file: UploadFile = File(...), gyro_file: UploadFile = File(...)):
    try:
        accel_df = pd.read_csv(acc_file.file)
        gyro_df = pd.read_csv(gyro_file.file)
        swings_json = analyze_swing(accel_df, gyro_df)
        feedback = get_feedback_from_gpt(swings_json)

        # Build summary for frontend boxes
        summary = {}
        if len(swings_json) > 0:
            first = swings_json[0]
            # Display ratio as "1:3" style
            tempo_str = None
            if first.get("tempo_ratio") is not None:
                ratio = round(first.get("tempo_ratio"), 2)
                tempo_str = f"1:{int(round(1/ratio))}" if ratio > 0 else "—"

            summary = {
                "tempo_ratio": tempo_str,
                "backswing_time": first.get("backswing_time"),
                "downswing_time": first.get("downswing_time"),
                "club_speed": round(first.get("club_speed_est", 0), 1),
                "impact_orientation": first.get("impact_orientation"),
                "impact_delta_angle": first.get("impact_delta_angle"),
            }

        return {"swings": swings_json, "feedback": feedback, "summary": summary}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
