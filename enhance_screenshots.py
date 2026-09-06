#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
App Store用スクリーンショット加工スクリプト
テキスト + グラデーション背景を追加
"""

from PIL import Image, ImageDraw, ImageFont
import os

# 入力・出力ディレクトリ
INPUT_DIR = "screenshots_appstore"
OUTPUT_DIR = "screenshots_enhanced"

# 各スクリーンショットのキャッチコピー
CAPTIONS = {
    "01_input_expense.png": "わずか3秒で記録完了",
    "02_analysis_graph.png": "美しいグラフで収支を可視化",
    "03_transaction_history.png": "すべての履歴を一目で確認",
    "04_input_income.png": "収入管理も簡単に",
    "05_settings.png": "自分好みにカスタマイズ"
}

# 色設定（ダークモードに合わせた洗練された色）
GRADIENT_START = (26, 26, 26, 240)  # ダークグレー（半透明）
GRADIENT_END = (0, 0, 0, 200)  # ブラック（半透明）
TEXT_COLOR = (128, 216, 255)  # ライトブルー（#80D8FF）
SHADOW_COLOR = (0, 0, 0, 180)  # 影

def create_gradient_overlay(width, height):
    """グラデーションオーバーレイを作成"""
    gradient = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(gradient)

    # グラデーションの高さ
    gradient_height = 280

    for i in range(gradient_height):
        # 上から下へのグラデーション
        alpha = int(240 * (1 - i / gradient_height))
        color = (26, 26, 26, alpha)
        draw.rectangle([(0, i), (width, i + 1)], fill=color)

    return gradient

def add_text_to_image(input_path, output_path, caption):
    """画像にテキストとグラデーションを追加"""
    # 画像を開く
    img = Image.open(input_path)

    # RGBAモードに変換
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # グラデーションオーバーレイを作成
    gradient = create_gradient_overlay(img.width, img.height)

    # グラデーションを画像に合成
    img = Image.alpha_composite(img, gradient)

    # テキストを描画
    draw = ImageDraw.Draw(img)

    # フォント設定（システムフォントを使用）
    try:
        # macOSのヒラギノフォントを使用
        font = ImageFont.truetype("/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc", 70)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 70)
        except:
            font = ImageFont.load_default()

    # テキストのサイズを取得
    bbox = draw.textbbox((0, 0), caption, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # テキストの位置（中央上部）
    x = (img.width - text_width) // 2
    y = 100

    # 影を描画（テキストの立体感を出す）
    shadow_offset = 4
    draw.text((x + shadow_offset, y + shadow_offset), caption, font=font, fill=SHADOW_COLOR)

    # メインテキストを描画
    draw.text((x, y), caption, font=font, fill=TEXT_COLOR)

    # RGB変換して保存
    img = img.convert('RGB')
    img.save(output_path, 'PNG', quality=95)
    print(f"✓ 作成完了: {os.path.basename(output_path)}")

def main():
    # 出力ディレクトリを作成
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("🎨 スクリーンショット加工を開始...")
    print()

    # 各画像を処理
    for filename, caption in CAPTIONS.items():
        input_path = os.path.join(INPUT_DIR, filename)
        output_path = os.path.join(OUTPUT_DIR, filename)

        if os.path.exists(input_path):
            add_text_to_image(input_path, output_path, caption)
        else:
            print(f"⚠ ファイルが見つかりません: {filename}")

    print()
    print("✨ すべての画像の加工が完了しました！")
    print(f"📁 保存先: {OUTPUT_DIR}/")

if __name__ == "__main__":
    main()
