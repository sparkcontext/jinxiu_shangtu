"""合成《錦繡商途》音頻素材:古箏風 BGM、三個場景環境音、UI 音效
全部使用 Karplus-Strong 撥弦與濾波噪聲合成,離線生成、無版權問題
"""
import numpy as np
import wave
import struct
import os

SR = 22050
OUT = r"C:\Projects\games\jinxiu_shangtu\assets\audio"
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(20260728)


def save_wav(name, samples):
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(name, f"{len(samples)/SR:.1f}s", os.path.getsize(os.path.join(OUT, name)) // 1024, "KB")


def karplus_strong(freq, duration, decay=0.996):
    """撥弦合成"""
    n = int(SR * duration)
    period = max(int(SR / freq), 2)
    buf = rng.uniform(-1, 1, period).astype(np.float64)
    out = np.zeros(n)
    idx = 0
    for i in range(n):
        out[i] = buf[idx]
        nxt = (idx + 1) % period
        buf[idx] = decay * 0.5 * (buf[idx] + buf[nxt])
        idx = nxt
    return out


def place(track, note, start):
    end = min(start + len(note), len(track))
    track[start:end] += note[: end - start]


# ---------- 古箏風 BGM:五聲音階,可無縫循環 ----------
def make_bgm():
    bpm = 66
    beat = 60.0 / bpm
    # 五聲音階(宮調式) C4 D4 E4 G4 A4 C5 D5 E5 G5
    scale = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25, 783.99]
    # 自編旋律(音階索引, 拍長),起承轉合,結尾回主音便於循環
    melody = [
        (4, 1.5), (5, 0.5), (7, 1), (5, 1), (4, 2),
        (3, 1), (4, 0.5), (5, 0.5), (3, 1), (1, 2),
        (2, 1.5), (3, 0.5), (4, 1), (2, 1), (0, 2),
        (4, 1), (3, 0.5), (2, 0.5), (1, 1), (0, 2),
        (7, 1.5), (5, 0.5), (4, 1), (5, 1), (7, 2),
        (8, 1), (7, 0.5), (5, 0.5), (4, 1), (5, 2),
        (4, 1.5), (3, 0.5), (2, 1), (1, 1), (0, 3),
    ]
    total_beats = sum(d for _, d in melody) + 2
    n = int(total_beats * beat * SR)
    track = np.zeros(n)
    t = 0.0
    for idx, dur in melody:
        freq = scale[idx]
        note = karplus_strong(freq, min(dur * beat + 1.2, 3.0), decay=0.997)
        note *= 0.55
        place(track, note, int(t * beat * SR))
        # 偶爾加低音陪襯
        if dur >= 2:
            bass = karplus_strong(freq / 2, 1.8, decay=0.998) * 0.25
            place(track, bass, int(t * beat * SR))
        t += dur
    # 淡入淡出端點,讓循環接縫自然
    fade = int(0.4 * SR)
    env = np.ones(n)
    env[:fade] = np.linspace(0.15, 1, fade)
    env[-fade:] = np.linspace(1, 0.15, fade)
    save_wav("bgm_guzheng.wav", track * env * 0.8)


def lowpass_noise(n, alpha):
    """簡單一階低通噪聲"""
    x = rng.uniform(-1, 1, n)
    y = np.zeros(n)
    acc = 0.0
    for i in range(n):
        acc = acc + alpha * (x[i] - acc)
        y[i] = acc
    return y


# ---------- 碼頭環境音:江浪 + 海鷗 + 遠處木箱敲擊 ----------
def make_amb_dock():
    dur = 24
    n = SR * dur
    waves = lowpass_noise(n, 0.06) * 2.2
    swell = 0.6 + 0.4 * np.sin(2 * np.pi * np.arange(n) / (6 * SR))
    track = waves * swell * 0.35
    # 海鷗鳴叫:下滑音
    for start_s in [3.2, 9.8, 15.1, 20.4]:
        L = int(0.5 * SR)
        tt = np.arange(L) / SR
        f = 2200 - 1400 * tt
        phase = 2 * np.pi * np.cumsum(f) / SR
        gull = np.sin(phase) * np.exp(-tt * 6) * 0.12
        place(track, gull, int(start_s * SR))
    # 木箱敲擊
    for start_s in [5.5, 12.0, 18.7, 22.3]:
        L = int(0.12 * SR)
        knock = rng.uniform(-1, 1, L) * np.exp(-np.arange(L) / (0.02 * SR)) * 0.3
        place(track, knock, int(start_s * SR))
    save_wav("amb_dock.wav", track)


# ---------- 宴會廳環境音:人聲雜沓 + 杯盤輕響 ----------
def make_amb_banquet():
    dur = 24
    n = SR * dur
    murmur = lowpass_noise(n, 0.18) * 1.6
    # 交談起伏包絡
    t = np.arange(n) / SR
    chatter = (0.55 + 0.25 * np.sin(2 * np.pi * 0.23 * t)
               + 0.2 * np.sin(2 * np.pi * 0.11 * t + 1.7))
    track = murmur * chatter * 0.3
    # 杯盤輕碰:高頻衰減鈴聲
    for start_s, f0 in [(2.5, 3400), (7.8, 2900), (11.2, 3600), (16.5, 3100), (21.0, 3400)]:
        L = int(0.35 * SR)
        tt = np.arange(L) / SR
        clink = np.sin(2 * np.pi * f0 * tt) * np.exp(-tt * 14) * 0.10
        place(track, clink, int(start_s * SR))
    save_wav("amb_banquet.wav", track)


# ---------- 客廳環境音:安靜午後,遠處時鐘滴答 ----------
def make_amb_parlor():
    dur = 24
    n = SR * dur
    room = lowpass_noise(n, 0.04) * 0.9
    track = room * 0.22
    for s in range(0, dur, 2):
        L = int(0.03 * SR)
        tick = rng.uniform(-1, 1, L) * np.exp(-np.arange(L) / (0.006 * SR)) * 0.10
        place(track, tick, int(s * SR))
    save_wav("amb_parlor.wav", track)


# ---------- UI 音效 ----------
def make_sfx():
    # 翻頁/繼續:短噪聲拂過
    L = int(0.09 * SR)
    page = rng.uniform(-1, 1, L) * np.exp(-np.arange(L) / (0.025 * SR)) * 0.35
    save_wav("sfx_page.wav", page)
    # 點擊/選項:短促木魚聲
    L = int(0.10 * SR)
    tt = np.arange(L) / SR
    click = np.sin(2 * np.pi * 900 * tt) * np.exp(-tt * 45) * 0.4
    save_wav("sfx_click.wav", click)
    # 銀兩入賬:清脆錢幣聲
    L = int(0.3 * SR)
    tt = np.arange(L) / SR
    coin = (np.sin(2 * np.pi * 2400 * tt) * np.exp(-tt * 20)
            + np.sin(2 * np.pi * 3200 * tt) * np.exp(-tt * 26)) * 0.3
    save_wav("sfx_coin.wav", coin)


make_bgm()
make_amb_dock()
make_amb_banquet()
make_amb_parlor()
make_sfx()
print("all audio synthesized")
