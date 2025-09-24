import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  static AudioPlayer? _audioPlayer;
  static FlutterTts? _flutterTts;
  static bool _isInitialized = false;

  // 랜덤 인사말 목록
  static const List<String> _greetings = [
    '어서오세요',
    '안녕하세요',
    '반갑습니다',
    '환영합니다',
    '좋은 하루 되세요',
  ];

  // 초기화
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 오디오 플레이어 초기화
      _audioPlayer = AudioPlayer();

      // TTS 초기화
      _flutterTts = FlutterTts();
      await _configureTts();

      _isInitialized = true;
      debugPrint('AudioService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AudioService: $e');
    }
  }

  // TTS 설정
  static Future<void> _configureTts() async {
    if (_flutterTts == null) return;

    try {
      // 한국어 설정
      await _flutterTts!.setLanguage('ko-KR');

      // 음성 속도 설정 (0.0 ~ 1.0)
      await _flutterTts!.setSpeechRate(0.6);

      // 음량 설정 (0.0 ~ 1.0)
      await _flutterTts!.setVolume(1.0);

      // 음높이 설정 (0.5 ~ 2.0)
      await _flutterTts!.setPitch(1.0);

      // 플랫폼별 설정
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _flutterTts!.setEngine('com.google.android.tts');
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts!.setSharedInstance(true);
      }

      debugPrint('TTS configured for Korean language');
    } catch (e) {
      debugPrint('Failed to configure TTS: $e');
    }
  }

  // 성공 사운드 재생
  static Future<void> playSuccessSound() async {
    try {
      if (_audioPlayer == null) {
        await initialize();
      }

      await _audioPlayer!.play(AssetSource('audio/ok.wav'));
      debugPrint('Success sound played');
    } catch (e) {
      debugPrint('Failed to play success sound: $e');
    }
  }

  // 실패 사운드 재생
  static Future<void> playFailSound() async {
    try {
      if (_audioPlayer == null) {
        await initialize();
      }

      await _audioPlayer!.play(AssetSource('audio/no.wav'));
      debugPrint('Fail sound played');
    } catch (e) {
      debugPrint('Failed to play fail sound: $e');
    }
  }

  // 성공 음성 안내 (TTS)
  static Future<void> playSuccess(String studentName, String stateText) async {
    try {
      if (_flutterTts == null) {
        await initialize();
      }

      // 랜덤 인사말 선택
      final random = Random();
      final greeting = _greetings[random.nextInt(_greetings.length)];

      // 음성 메시지 생성
      final message = '$studentName님이 $stateText 되었습니다. $greeting.';

      debugPrint('Playing TTS message: $message');

      // 먼저 성공 사운드 재생
      await playSuccessSound();

      // 짧은 지연 후 TTS 재생
      await Future.delayed(const Duration(milliseconds: 500));

      // TTS 재생
      await _flutterTts!.speak(message);
    } catch (e) {
      debugPrint('Failed to play success TTS: $e');
    }
  }

  // 실패 음성 안내
  static Future<void> playFail([String? customMessage]) async {
    try {
      if (_flutterTts == null) {
        await initialize();
      }

      // 기본 실패 메시지
      final message = customMessage ?? '얼굴인식에 실패했습니다. 다시 시도해 주세요.';

      debugPrint('Playing fail TTS message: $message');

      // 먼저 실패 사운드 재생
      await playFailSound();

      // 짧은 지연 후 TTS 재생
      await Future.delayed(const Duration(milliseconds: 500));

      // TTS 재생
      await _flutterTts!.speak(message);
    } catch (e) {
      debugPrint('Failed to play fail TTS: $e');
    }
  }

  // 일반 TTS 메시지 재생
  static Future<void> speak(String message) async {
    try {
      if (_flutterTts == null) {
        await initialize();
      }

      debugPrint('Speaking: $message');
      await _flutterTts!.speak(message);
    } catch (e) {
      debugPrint('Failed to speak message: $e');
    }
  }

  // TTS 중지
  static Future<void> stopSpeaking() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.stop();
        debugPrint('TTS stopped');
      }
    } catch (e) {
      debugPrint('Failed to stop TTS: $e');
    }
  }

  // 사운드 중지
  static Future<void> stopSound() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        debugPrint('Audio stopped');
      }
    } catch (e) {
      debugPrint('Failed to stop audio: $e');
    }
  }

  // 모든 오디오 중지
  static Future<void> stopAll() async {
    await stopSpeaking();
    await stopSound();
  }

  // 상태별 안내 메시지 재생
  static Future<void> playStateMessage({
    required String studentName,
    required int state,
    bool isSuccess = true,
    String? customMessage,
  }) async {
    if (!isSuccess) {
      await playFail(customMessage);
      return;
    }

    String stateText;
    switch (state) {
      case 1:
        stateText = '등원처리';
        break;
      case 2:
        stateText = '하원처리';
        break;
      case 3:
        stateText = '외출처리';
        break;
      case 4:
        stateText = '복귀처리';
        break;
      case 5:
        stateText = '조퇴처리';
        break;
      default:
        stateText = '처리';
    }

    await playSuccess(studentName, stateText);
  }

  // 키패드 입력 사운드 (시스템 사운드 사용)
  static Future<void> playKeypadSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('Failed to play keypad sound: $e');
    }
  }

  // 에러 사운드 (시스템 사운드 사용)
  static Future<void> playErrorSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('Failed to play error sound: $e');
    }
  }

  // 음량 설정
  static Future<void> setVolume(double volume) async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.setVolume(volume);
      }

      if (_flutterTts != null) {
        await _flutterTts!.setVolume(volume);
      }

      debugPrint('Volume set to: $volume');
    } catch (e) {
      debugPrint('Failed to set volume: $e');
    }
  }

  // TTS 속도 설정
  static Future<void> setSpeechRate(double rate) async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.setSpeechRate(rate);
        debugPrint('Speech rate set to: $rate');
      }
    } catch (e) {
      debugPrint('Failed to set speech rate: $e');
    }
  }

  // TTS 음높이 설정
  static Future<void> setPitch(double pitch) async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.setPitch(pitch);
        debugPrint('Pitch set to: $pitch');
      }
    } catch (e) {
      debugPrint('Failed to set pitch: $e');
    }
  }

  // 사용 가능한 TTS 언어 목록 조회
  static Future<List<dynamic>> getAvailableLanguages() async {
    try {
      if (_flutterTts == null) {
        await initialize();
      }

      final languages = await _flutterTts!.getLanguages;
      debugPrint('Available TTS languages: $languages');
      return languages ?? [];
    } catch (e) {
      debugPrint('Failed to get available languages: $e');
      return [];
    }
  }

  // 현재 TTS 설정 정보 조회
  static Future<Map<String, dynamic>> getTtsInfo() async {
    try {
      if (_flutterTts == null) {
        await initialize();
      }

      final info = {
        'language': await _flutterTts!.getLanguages,
        'engines': await _flutterTts!.getEngines,
        'voices': await _flutterTts!.getVoices,
      };

      return info;
    } catch (e) {
      debugPrint('Failed to get TTS info: $e');
      return {};
    }
  }

  // TTS 상태 확인
  static bool get isTtsInitialized => _flutterTts != null;

  // 오디오 플레이어 상태 확인
  static bool get isAudioInitialized => _audioPlayer != null;

  // 서비스 초기화 상태 확인
  static bool get isInitialized => _isInitialized;

  // 리소스 해제
  static Future<void> dispose() async {
    try {
      await stopAll();

      if (_audioPlayer != null) {
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }

      if (_flutterTts != null) {
        await _flutterTts!.stop();
        _flutterTts = null;
      }

      _isInitialized = false;
      debugPrint('AudioService disposed');
    } catch (e) {
      debugPrint('Failed to dispose AudioService: $e');
    }
  }

  // 커스텀 사운드 파일 재생 (추후 확장용)
  static Future<void> playCustomSound(String assetPath) async {
    try {
      if (_audioPlayer == null) {
        await initialize();
      }

      await _audioPlayer!.play(AssetSource(assetPath));
      debugPrint('Custom sound played: $assetPath');
    } catch (e) {
      debugPrint('Failed to play custom sound: $e');
    }
  }

  // 테스트용 메서드들
  static Future<void> testTts() async {
    await speak('음성 테스트입니다. 잘 들리시나요?');
  }

  static Future<void> testSounds() async {
    debugPrint('Testing success sound...');
    await playSuccessSound();

    await Future.delayed(const Duration(seconds: 2));

    debugPrint('Testing fail sound...');
    await playFailSound();
  }

  static Future<void> testFullFlow() async {
    debugPrint('Testing full audio flow...');

    await playSuccess('홍길동', '등원처리');

    await Future.delayed(const Duration(seconds: 3));

    await playFail('얼굴을 인식할 수 없습니다.');
  }
}