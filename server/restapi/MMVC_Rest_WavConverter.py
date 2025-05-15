import os
import base64
import traceback
import threading
import numpy as np
import struct
from typing import Optional
from fastapi import APIRouter, UploadFile, File, Form
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse, FileResponse
from scipy.io.wavfile import read, write

from voice_changer.VoiceChangerManager import VoiceChangerManager
from const import UPLOAD_DIR, UPLOAD_TEMP_DIR

# アップロードディレクトリの作成
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(UPLOAD_TEMP_DIR, exist_ok=True)

class MMVC_Rest_WavConverter:
    def __init__(self, voiceChangerManager: VoiceChangerManager):
        self.voiceChangerManager = voiceChangerManager
        self.router = APIRouter()
        self.router.add_api_route("/convert_wav", self.convert_wav, methods=["POST"])
        self.router.add_api_route("/convert_wav_file", self.convert_wav_file, methods=["POST"])
        self.tlock = threading.Lock()

    def convert_wav(self, wav_base64: str = Form(...)):
        """
        Base64エンコードされたWAVデータを受け取り、変換した音声を返す
        """
        try:
            # Base64デコード
            wav_data = base64.b64decode(wav_base64)
            
            # WAVデータをnumpy配列に変換
            unpackedData = np.array(struct.unpack("<%sh" % (len(wav_data) // struct.calcsize("<h")), wav_data)).astype(np.int16)
            
            # 音声変換
            self.tlock.acquire()
            changedVoice = self.voiceChangerManager.changeVoice(unpackedData)
            self.tlock.release()
            
            # 変換後の音声をBase64エンコード
            changedVoiceBase64 = base64.b64encode(changedVoice[0]).decode("utf-8")
            
            # レスポンス作成
            data = {"changedVoiceBase64": changedVoiceBase64}
            json_compatible_item_data = jsonable_encoder(data)
            
            return JSONResponse(content=json_compatible_item_data)
            
        except Exception as e:
            print("WAV CONVERSION EXCEPTION:", e)
            print(traceback.format_exc())
            if self.tlock.locked():
                self.tlock.release()
            return JSONResponse(content={"error": str(e)}, status_code=500)

    def convert_wav_file(self, file: UploadFile = File(...), output_filename: Optional[str] = Form(None)):
        """
        WAVファイルをアップロードして変換し、変換後のファイルをダウンロード
        """
        try:
            # 入力ファイルの保存
            input_path = os.path.join(UPLOAD_TEMP_DIR, file.filename)
            output_filename = output_filename or f"converted_{file.filename}"
            output_path = os.path.join(UPLOAD_TEMP_DIR, output_filename)
            
            # アップロードファイルの保存
            with open(input_path, "wb") as f:
                f.write(file.file.read())
            
            # WAVファイル読み込み
            sampling_rate, wav_data = read(input_path)
            
            # 音声変換
            self.tlock.acquire()
            changedVoice = self.voiceChangerManager.changeVoice(wav_data)
            self.tlock.release()
            
            # 変換後の音声をファイルに保存
            write(output_path, sampling_rate, changedVoice[0].astype(np.int16))
            
            # ファイルをレスポンスとして返す
            return FileResponse(
                path=output_path,
                filename=output_filename,
                media_type="audio/wav"
            )
            
        except Exception as e:
            print("WAV FILE CONVERSION EXCEPTION:", e)
            print(traceback.format_exc())
            if self.tlock.locked():
                self.tlock.release()
            return JSONResponse(content={"error": str(e)}, status_code=500) 