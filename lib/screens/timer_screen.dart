import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  Duration _duration = Duration.zero;
  Duration _initialDuration = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  bool _isCountdown = false;
  final TextEditingController _countdownController = TextEditingController();

  // Ayarlar için yeni değişkenler
  int _defaultPomodoroMinutes = 25; // Varsayılan Pomodoro süresi
  bool _vibrateEnabled = true; // Titreşim açık mı?
  bool _soundEnabled =
      false; // Ses açık mı? (Şimdilik sadece değişken, ses çalma özelliği sonra eklenecek)
  final TextEditingController _settingsPomodoroController =
      TextEditingController();

  // Ses çalmak için AudioPlayer instance'ı
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _soundPath =
      'sounds/completion_sound.mp3'; // Ses dosyasının yolu

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Ayarları yükle

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownController.dispose();
    _settingsPomodoroController.dispose(); // Ayarlar controller'ını dispose et
    _audioPlayer.dispose(); // AudioPlayer'ı dispose et
    _animationController.dispose();
    super.dispose();
  }

  // Ayarları SharedPreferences'tan yükle
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultPomodoroMinutes = prefs.getInt('defaultPomodoroMinutes') ?? 25;
      _vibrateEnabled = prefs.getBool('vibrateEnabled') ?? true;
      _soundEnabled = prefs.getBool('soundEnabled') ?? false;

      // Yüklenen varsayılan süreyi geri sayım modu için ayarla (eğer timer 0 ise)
      if (_isCountdown && _duration == Duration.zero) {
        _duration = Duration(minutes: _defaultPomodoroMinutes);
      }
      // Yüklenen varsayılan süreyi başlangıç süresi olarak ayarla (progress bar için)
      if (_isCountdown) {
        _initialDuration = Duration(minutes: _defaultPomodoroMinutes);
      }
    });
    // Yüklenen varsayılan süreyi ayarlar controller'ına yaz
    _settingsPomodoroController.text = _defaultPomodoroMinutes.toString();
  }

  // Ayarları SharedPreferences'a kaydet
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultPomodoroMinutes', _defaultPomodoroMinutes);
    await prefs.setBool('vibrateEnabled', _vibrateEnabled);
    await prefs.setBool('soundEnabled', _soundEnabled);
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      if (_isCountdown && _initialDuration == Duration.zero) {
        _initialDuration = _duration;
      }
    });

    _animationController.repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_isCountdown) {
          if (_duration.inSeconds > 0) {
            _duration = _duration - const Duration(seconds: 1);
          } else {
            _stopTimer();
            if (_vibrateEnabled) {
              _vibrate();
            }
            if (_soundEnabled) {
              _playCompletionSound();
            }
            _showCompletionDialog();
          }
        } else {
          _duration = _duration + const Duration(seconds: 1);
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _animationController.stop();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _duration = Duration.zero;
      _initialDuration = Duration.zero;
      _countdownController.clear();
    });
  }

  void _vibrate() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator ?? false) {
      if (_vibrateEnabled) {
        Vibration.vibrate(duration: 1000);
      }
    }
  }

  // Ses çalma metodu
  void _playCompletionSound() async {
    try {
      await _audioPlayer.play(AssetSource(_soundPath));
    } catch (e) {
      print('Ses çalınırken hata oluştu: $e');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Tebrikler!'),
            ],
          ),
          content: const Text('Pomodoro seansınız tamamlandı!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetTimer();
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  double get _progress {
    if (!_isCountdown || _initialDuration.inSeconds == 0) return 0.0;
    return (_initialDuration.inSeconds - _duration.inSeconds) /
        _initialDuration.inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A1A2E)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Pomodoro Timer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Mod seçimi
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16213E) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_isCountdown) {
                            _resetTimer();
                            setState(() {
                              _isCountdown = false;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isCountdown
                                ? const Color(0xFF6C5CE7)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Kronometre',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isCountdown
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white70
                                        : Colors.grey[600]),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_isCountdown) {
                            _resetTimer();
                            setState(() {
                              _isCountdown = true;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isCountdown
                                ? const Color(0xFFE17055)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Geri Sayım',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isCountdown
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white70
                                        : Colors.grey[600]),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Süre girişi (sadece pomodoro modunda)
              if (_isCountdown) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF16213E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tıklanabilir süre seçici
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.remove_circle_outline,
                              size: 36,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                            onPressed: _isRunning
                                ? null
                                : () {
                                    setState(() {
                                      if (_duration.inMinutes > 0) {
                                        _duration =
                                            _duration -
                                            const Duration(minutes: 1);
                                        _initialDuration =
                                            _duration; // Başlangıç süresini de güncelle
                                      }
                                    });
                                  },
                          ),
                          Text(
                            '${_duration.inMinutes} dakika',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              size: 36,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                            onPressed: _isRunning
                                ? null
                                : () {
                                    setState(() {
                                      _duration =
                                          _duration +
                                          const Duration(minutes: 1);
                                      _initialDuration =
                                          _duration; // Başlangıç süresini de güncelle
                                    });
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],

              // Ana timer widget'ı
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isRunning ? _scaleAnimation.value : 1.0,
                        child: SizedBox(
                          width: 280,
                          height: 280,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Arka plan çemberi
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? [
                                            const Color(0xFF16213E),
                                            const Color(0xFF0F3460),
                                          ]
                                        : [
                                            Colors.white,
                                            const Color(0xFFF8F9FA),
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(
                                        isDark ? 0.05 : 0.7,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(-10, -10),
                                    ),
                                  ],
                                ),
                              ),

                              // Progress indicator (sadece countdown modunda)
                              if (_isCountdown)
                                SizedBox(
                                  width: 260,
                                  height: 260,
                                  child: CircularProgressIndicator(
                                    value: _progress,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFE17055),
                                        ),
                                  ),
                                ),

                              // Zaman metni
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatDuration(_duration),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: _isCountdown
                                          ? const Color(0xFFE17055)
                                          : const Color(0xFF6C5CE7),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isRunning
                                        ? (_isCountdown
                                              ? 'Odaklan'
                                              : 'Çalışıyor')
                                        : 'Hazır',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Kontrol butonları
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset butonu
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF16213E) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(35),
                        onTap: _resetTimer,
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 30,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),

                  // Play/Pause butonu
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isCountdown
                            ? [const Color(0xFFE17055), const Color(0xFFD63031)]
                            : [
                                const Color(0xFF6C5CE7),
                                const Color(0xFF5A52D5),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isCountdown
                                      ? const Color(0xFFE17055)
                                      : const Color(0xFF6C5CE7))
                                  .withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(45),
                        onTap: _isRunning ? _stopTimer : _startTimer,
                        child: Icon(
                          _isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Settings butonu (placeholder)
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF16213E) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(35),
                        onTap: _showSettingsDialog,
                        child: Icon(
                          Icons.settings_rounded,
                          size: 30,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Yeni ayarlar penceresi metodu
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Dialog içeriği için yerel durum yönetimi
        int tempPomodoroMinutes = _defaultPomodoroMinutes;
        bool tempVibrateEnabled = _vibrateEnabled;
        bool tempSoundEnabled = _soundEnabled;

        return AlertDialog(
          title: const Text('Ayarlar'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: TextEditingController(
                        text: tempPomodoroMinutes.toString(),
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pomodoro Süresi (dakika)',
                      ),
                      onChanged: (value) {
                        int? minutes = int.tryParse(value);
                        if (minutes != null && minutes >= 0) {
                          setState(() {
                            tempPomodoroMinutes = minutes;
                          });
                        } else if (value.isEmpty) {
                          setState(() {
                            tempPomodoroMinutes = 0;
                          });
                        } // Geçersiz girişlerde önceki değeri tutmak veya hata göstermek isteyebilirsiniz.
                      },
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text('Titreşim Açık'),
                      value: tempVibrateEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          tempVibrateEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Ses Çal'),
                      value: tempSoundEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          tempSoundEnabled = value;
                        });
                        // TODO: Ses çalma özelliği buraya eklenecek
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Tamam'),
              onPressed: () async {
                // Ana widget'ın durumunu güncelle
                setState(() {
                  _defaultPomodoroMinutes = tempPomodoroMinutes;
                  _vibrateEnabled = tempVibrateEnabled;
                  _soundEnabled = tempSoundEnabled;

                  // Eğer geri sayım modundaysak ve zamanlayıcı çalışmıyorsa veya süre 0 ise
                  // yeni varsayılan süreyi uygula
                  if (_isCountdown &&
                      !_isRunning &&
                      _duration == Duration.zero) {
                    _duration = Duration(minutes: _defaultPomodoroMinutes);
                  }
                  // Eğer geri sayım modundaysak ve zamanlayıcı çalışmıyorsa
                  // başlangıç süresini de güncelle (progress bar için)
                  if (_isCountdown && !_isRunning) {
                    _initialDuration = Duration(
                      minutes: _defaultPomodoroMinutes,
                    );
                  }
                });
                // Ayarları kalıcı olarak kaydet
                _saveSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
