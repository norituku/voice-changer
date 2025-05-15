import os
import sys
import base64
import tempfile
import numpy as np
import torch
import json
from flask import Flask, request, jsonify, send_file
from scipy.io.wavfile import read, write

# 必要なディレクトリの作成
UPLOAD_DIR = "upload_dir"
UPLOAD_TEMP_DIR = os.path.join(UPLOAD_DIR, "temp")
MODEL_DIR = "model_dir"
os.makedirs(UPLOAD_TEMP_DIR, exist_ok=True)

# 元のシステムからの必要なモジュールをインポート
sys.path.append(os.path.join(os.path.dirname(__file__), "server"))
from voice_changer.utils.VoiceChangerParams import VoiceChangerParams
from voice_changer.RVC.RVC import RVC
from data.ModelSlot import RVCModelSlot

app = Flask(__name__)

# RVCモデルの初期化
def load_rvc_model(model_dir, slot_id):
    """RVCモデルをロードする関数"""
    try:
        # スロット情報の読み込み
        params_path = os.path.join(model_dir, str(slot_id), "params.json")
        with open(params_path, "r", encoding="utf-8") as f:
            slot_info_dict = json.load(f)
        
        # RVCModelSlotオブジェクトの作成
        slot_info = RVCModelSlot(**slot_info_dict)
        
        # VoiceChangerParamsの作成
        vc_params = VoiceChangerParams()
        vc_params.model_dir = model_dir
        
        # RVCモデルのインスタンス作成
        rvc_model = RVC(vc_params, slot_info)
        rvc_model.initialize()
        
        print(f"RVCモデルを正常にロードしました: {slot_info.name}")
        return rvc_model
    except Exception as e:
        print(f"RVCモデルのロード中にエラーが発生しました: {str(e)}")
        return None

# グローバル変数としてRVCモデルをロード
rvc_model = load_rvc_model(MODEL_DIR, 2)  # スロットID 2のモデルをロード

@app.route('/', methods=['GET'])
def index():
    return jsonify({
        "status": "running",
        "endpoints": {
            "GET /": "このヘルプメッセージ",
            "GET /convert_model_info": "利用可能なモデル情報",
            "POST /convert_wav_file": "WAVファイル変換 (multipart/form-data形式: file, output_filename, f0_up_key, index_ratio, protect)"
        }
    })

@app.route('/convert_model_info', methods=['GET'])
def get_model_info():
    if rvc_model is not None:
        model_info = rvc_model.get_info()
        return jsonify({
            "status": "success",
            "model_loaded": True,
            "model_info": model_info
        })
    else:
        return jsonify({
            "status": "error",
            "model_loaded": False,
            "message": "モデルがロードされていません"
        })

@app.route('/convert_wav_file', methods=['POST'])
def convert_wav_file():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    output_filename = request.form.get('output_filename', f"converted_{file.filename}")
    
    # 変換パラメータの取得
    f0_up_key = float(request.form.get('f0_up_key', 0))  # 音程変更（半音単位）
    index_ratio = float(request.form.get('index_ratio', 0))  # インデックス比率 (0.0-1.0)
    protect = float(request.form.get('protect', 0.5))  # 保護率 (0.0-1.0)
    
    # ファイルを一時的に保存
    temp_input_path = os.path.join(UPLOAD_TEMP_DIR, file.filename)
    output_path = os.path.join(UPLOAD_TEMP_DIR, output_filename)
    
    file.save(temp_input_path)
    
    # WAVファイルを読み込み
    try:
        sampling_rate, wav_data = read(temp_input_path)
        wav_data = wav_data.astype(np.float32)
        
        # RVCモデルが利用可能か確認
        if rvc_model is None:
            # モデルがロードされていない場合は簡易変換（音量を下げるだけ）
            print("RVCモデルが利用できないため、簡易変換を行います")
            modified_wav_data = wav_data * 0.8
            modified_wav_data = modified_wav_data.astype(np.int16)
        else:
            # RVCモデルを使った変換処理
            print(f"RVCモデルで変換を行います: f0_up_key={f0_up_key}, index_ratio={index_ratio}, protect={protect}")
            print(f"Input shape: {wav_data.shape}, Sample rate: {sampling_rate}")
            
            # パラメータの設定
            rvc_model.settings.tran = f0_up_key
            rvc_model.settings.indexRatio = index_ratio
            rvc_model.settings.protect = protect
            
            # 入力データの前処理
            # AudioInOutオブジェクトとして扱うため、整数型に変換
            wav_int16 = wav_data.astype(np.int16)
            
            # 変換処理
            input_data = rvc_model.generate_input(wav_int16, wav_int16.shape[0], 0)
            output_data = rvc_model.inference(input_data)
            
            # 変換結果を保存
            modified_wav_data = output_data.astype(np.int16)
        
        write(output_path, sampling_rate, modified_wav_data)
        
        print(f"変換完了。出力ファイル: {output_path}")
        
        # 処理が完了したらファイルを返す
        return send_file(output_path, mimetype='audio/wav', as_attachment=True, download_name=output_filename)
    
    except Exception as e:
        import traceback
        print(f"変換中にエラーが発生しました: {str(e)}")
        print(traceback.format_exc())
        return jsonify({"error": str(e), "traceback": traceback.format_exc()}), 500

if __name__ == '__main__':
    print(f"WAV変換サーバーを開始します: http://0.0.0.0:18888")
    app.run(host='0.0.0.0', port=18888, debug=False) 