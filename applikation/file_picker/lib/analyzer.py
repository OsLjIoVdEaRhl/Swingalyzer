# main.py
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
import numpy as np
from scipy.signal import find_peaks, butter, filtfilt
import json
import os
from dotenv import load_dotenv
import openai
 
# ===== Load API key from .env =====
load_dotenv()
OPENAI_API_KEY = os.getenv("sk-svcacct-3Btrt3rDipAVDd_E1YocrR8SNjOnSC4Tszl1HbV3hrcncIVKcJp7KeAgDurZkT3BlbkFJOWNief0IByC2_mcNd7_p6ksU1q1_gLNJ-L6JUyx0LK7Sv5mGoddlKnvOpoJkwA")
openai.api_key = OPENAI_API_KEY
# ===== Config =====
LOWPASS_CUTOFF = 20.0
EXPECTED_FS = 208.0
MIN_FS = 30.0
MAX_FS = 1000.0
MIN_SWING_INTERVAL_S = 0.4
 
app = FastAPI()
 
# Allow requests from Flutter app
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
    if cutoff_hz >= nyq:
        return data
    b, a = butter(order, cutoff_hz / nyq, btype='low')
    return filtfilt(b, a, data)
 
# ===== Swing Analysis =====
def analyze_swing(accel_df, gyro_df):
    ts_raw = accel_df['timestamp'].values.astype(np.float64)
    ax = accel_df['x'].values.astype(np.float64)
    ay = accel_df['y'].values.astype(np.float64)
    az = accel_df['z'].values.astype(np.float64)
    n = len(ts_raw)
 
    # Timestamp conversion
    candidates = {'seconds':1.0, 'milliseconds':1e3, 'microseconds':1e6}
    best = None
    best_score = 1e9
    for name, div in candidates.items():
        time_cand = (ts_raw - ts_raw[0]) / div
        dt = np.diff(time_cand)
        if np.any(dt <= 0):
            continue
        fs_cand = 1.0 / np.median(dt)
        valid = (MIN_FS <= fs_cand <= MAX_FS)
        score = abs(fs_cand - EXPECTED_FS) if valid else abs(fs_cand - EXPECTED_FS)+1e6
        if score < best_score:
            best_score = score
            best = name
 
    if best is None:
        time = np.arange(n)/EXPECTED_FS
        fs = EXPECTED_FS
    else:
        time = (ts_raw - ts_raw[0])/candidates[best]
        fs = 1.0/np.median(np.diff(time))
 
    a_res = np.sqrt(ax**2 + ay**2 + az**2)
    gx = gyro_df['x'].values.astype(np.float64)
    gy = gyro_df['y'].values.astype(np.float64)
    gz = gyro_df['z'].values.astype(np.float64)
    omega_res = np.sqrt(gx**2 + gy**2 + gz**2)
 
    a_filt = lowpass(a_res, LOWPASS_CUTOFF, fs)
    omega_filt = lowpass(omega_res, LOWPASS_CUTOFF, fs)
 
    # Peaks detection
    signal_span = np.max(a_filt) - np.median(a_filt)
    prominence = max(0.6*signal_span, 1e-6)
    distance_samples = max(1,int(MIN_SWING_INTERVAL_S*fs))
    peaks, _ = find_peaks(a_filt, prominence=prominence, distance=distance_samples)
 
    swings = []
    for i, p in enumerate(peaks):
        peak_val = a_filt[p]
        # Downswing start
        lookback_samples = int(2.0*fs)
        start_search = max(0,p-lookback_samples)
        baseline = np.median(a_filt[start_search:p+1])
        thr = baseline + 0.12*(peak_val - baseline)
        idxs = np.where(a_filt[start_search:p]<=thr)[0]
        downswing_start_idx = start_search + idxs[-1] + 1 if len(idxs)>0 else max(start_search,p-int(0.5*fs))
        # Impact
        lookahead_samples = int(1.0*fs)
        end_search = min(n-1,p+lookahead_samples)
        segment_after_peak = a_filt[p:end_search+1]
        if len(segment_after_peak)>2:
            impact_rel = np.where(segment_after_peak < 0.8*peak_val)[0]
            impact_idx = p + impact_rel[0] if len(impact_rel)>0 else end_search
        else:
            impact_idx = p
        # Backswing start
        prev_boundary = peaks[i-1] if i>0 else max(0,p-int(3.0*fs))
        segment_start = prev_boundary
        segment_end = downswing_start_idx
        if segment_end <= segment_start:
            segment_start = max(0, downswing_start_idx-int(0.5*fs))
        local_window = a_filt[segment_start:segment_end+1]
        backswing_start_idx = segment_start + np.argmin(local_window) if len(local_window)>0 else max(0,downswing_start_idx-int(0.5*fs))
        # Times
        downswing_time = time[impact_idx] - time[downswing_start_idx]
        backswing_time = time[downswing_start_idx] - time[backswing_start_idx]
        tempo_ratio = backswing_time / downswing_time if downswing_time>0 else None
        # Gyro metrics
        avg_gyro_backswing = np.mean(omega_filt[backswing_start_idx:downswing_start_idx])
        avg_gyro_downswing = np.mean(omega_filt[downswing_start_idx:impact_idx])
        max_gyro = np.max(omega_filt[downswing_start_idx:impact_idx])
        # Wrist angles
        wx_start = gx[backswing_start_idx]
        wy_start = gy[backswing_start_idx]
        wz_start = gz[backswing_start_idx]
        wx_impact = gx[impact_idx]
        wy_impact = gy[impact_idx]
        wz_impact = gz[impact_idx]
        swings.append({
            "swing_number": i+1,
            "backswing_time": round(float(backswing_time),3),
            "downswing_time": round(float(downswing_time),3),
            "tempo_ratio": round(float(tempo_ratio),2) if tempo_ratio else None,
            "max_accel": round(float(peak_val),2),
            "max_gyro": round(float(max_gyro),2),
            "avg_gyro_backswing": round(float(avg_gyro_backswing),2),
            "avg_gyro_downswing": round(float(avg_gyro_downswing),2),
            "impact_time": round(float(time[impact_idx]),3),
            "wrist_start": {"x": wx_start, "y": wy_start, "z": wz_start},
            "wrist_impact": {"x": wx_impact, "y": wy_impact, "z": wz_impact},
            "wrist_change": {"x": wx_impact-wx_start, "y": wy_impact-wy_start, "z": wz_impact-wz_start}
        })
    return swings
 
# ===== GPT Feedback =====
def get_feedback_from_gpt(swings_json):
    prompt = f"Analyze these golf swings and give feedback:\n{json.dumps(swings_json, indent=2)}"
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[{"role":"user","content":prompt}],
        temperature=0.5
    )
    return response.choices[0].message.content
 
# ===== API Endpoint =====
@app.post("/analyze_swing")
async def analyze_swing_endpoint(acc_file: UploadFile = File(...), gyro_file: UploadFile = File(...)):
    print("✅ API endpoint '/analyze_swing' was called!")

    accel_df = pd.read_csv(acc_file.file)
    gyro_df = pd.read_csv(gyro_file.file)
    swings_json = analyze_swing(accel_df, gyro_df)
    feedback = get_feedback_from_gpt(swings_json)
    return {"swings": swings_json, "feedback": feedback}