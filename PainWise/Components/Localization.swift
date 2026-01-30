import Foundation

// MARK: - Localization Helper
enum L10n {
    // MARK: - App
    static let appName = String(localized: "app_name")
    static let appSubtitle = String(localized: "app_subtitle")

    // MARK: - Greetings
    static let greetingMorning = String(localized: "greeting_morning")
    static let greetingAfternoon = String(localized: "greeting_afternoon")
    static let greetingEvening = String(localized: "greeting_evening")

    // MARK: - Tab Bar
    static let tabHome = String(localized: "tab_home")
    static let tabRecord = String(localized: "tab_record")
    static let tabHistory = String(localized: "tab_history")
    static let tabAnalysis = String(localized: "tab_analysis")
    static let tabForecast = String(localized: "tab_forecast")
    static let tabSettings = String(localized: "tab_settings")

    // MARK: - Dashboard
    static let dashboardRecordCurrentState = String(localized: "dashboard_record_current_state")
    static let dashboardRecordButton = String(localized: "dashboard_record_button")
    static let dashboardRecommendedAdvice = String(localized: "dashboard_recommended_advice")
    static let dashboardLoadingWeather = String(localized: "dashboard_loading_weather")
    static let dashboardEnableLocation = String(localized: "dashboard_enable_location")

    // MARK: - Forecast Messages
    static let forecastLowPressureWarning = String(localized: "forecast_low_pressure_warning")
    static let forecastHighPressure = String(localized: "forecast_high_pressure")
    static let forecastStablePressure = String(localized: "forecast_stable_pressure")

    // MARK: - Forecast Card
    static let forecastCardAlert = String(localized: "forecast_card_alert")
    static let forecastCardPressure = String(localized: "forecast_card_pressure")
    static let forecastCardAccuracy = String(localized: "forecast_card_accuracy")

    // MARK: - Alert Levels
    static let alertLevelLow = String(localized: "alert_level_low")
    static let alertLevelMedium = String(localized: "alert_level_medium")
    static let alertLevelHigh = String(localized: "alert_level_high")

    // MARK: - Weekly Chart
    static let weeklyChartTitle = String(localized: "weekly_chart_title")
    static let weeklyChartPainLevel = String(localized: "weekly_chart_pain_level")
    static let weeklyChartNoData = String(localized: "weekly_chart_no_data")

    // MARK: - Advice
    static let adviceCategoryRelax = String(localized: "advice_category_relax")
    static let adviceCategoryExercise = String(localized: "advice_category_exercise")
    static let adviceTeaTitle = String(localized: "advice_tea_title")
    static let adviceTeaDescription = String(localized: "advice_tea_description")
    static let adviceStretchTitle = String(localized: "advice_stretch_title")
    static let adviceStretchDescription = String(localized: "advice_stretch_description")

    // MARK: - Quick Record
    static let quickRecordTitle = String(localized: "quick_record_title")
    static let quickRecordPainLevel = String(localized: "quick_record_pain_level")
    static let quickRecordBodyParts = String(localized: "quick_record_body_parts")
    static let quickRecordSelectParts = String(localized: "quick_record_select_parts")
    static let quickRecordNote = String(localized: "quick_record_note")
    static let quickRecordNotePlaceholder = String(localized: "quick_record_note_placeholder")
    static let quickRecordSave = String(localized: "quick_record_save")
    static let quickRecordCancel = String(localized: "quick_record_cancel")
    static let quickRecordWeatherInfo = String(localized: "quick_record_weather_info")
    static let quickRecordHealthInfo = String(localized: "quick_record_health_info")

    // MARK: - Pain Severity
    static let painSeverityNone = String(localized: "pain_severity_none")
    static let painSeverityMild = String(localized: "pain_severity_mild")
    static let painSeverityModerate = String(localized: "pain_severity_moderate")
    static let painSeveritySevere = String(localized: "pain_severity_severe")
    static let painSeverityExtreme = String(localized: "pain_severity_extreme")

    // MARK: - Body Parts
    static let bodyPartHead = String(localized: "body_part_head")
    static let bodyPartNeck = String(localized: "body_part_neck")
    static let bodyPartShoulder = String(localized: "body_part_shoulder")
    static let bodyPartBack = String(localized: "body_part_back")
    static let bodyPartLowerBack = String(localized: "body_part_lower_back")
    static let bodyPartChest = String(localized: "body_part_chest")
    static let bodyPartAbdomen = String(localized: "body_part_abdomen")
    static let bodyPartArm = String(localized: "body_part_arm")
    static let bodyPartElbow = String(localized: "body_part_elbow")
    static let bodyPartWrist = String(localized: "body_part_wrist")
    static let bodyPartHand = String(localized: "body_part_hand")
    static let bodyPartHip = String(localized: "body_part_hip")
    static let bodyPartThigh = String(localized: "body_part_thigh")
    static let bodyPartKnee = String(localized: "body_part_knee")
    static let bodyPartCalf = String(localized: "body_part_calf")
    static let bodyPartAnkle = String(localized: "body_part_ankle")
    static let bodyPartFoot = String(localized: "body_part_foot")

    // MARK: - History
    static let historyTitle = String(localized: "history_title")
    static let historyCreatePdf = String(localized: "history_create_pdf")
    static let historyGeneratingPdf = String(localized: "history_generating_pdf")
    static let historySearchPlaceholder = String(localized: "history_search_placeholder")
    static let historyFilterPeriod = String(localized: "history_filter_period")
    static let historyFilterBodyPart = String(localized: "history_filter_body_part")
    static let historyFilterIntensity = String(localized: "history_filter_intensity")
    static let historyFilterAll = String(localized: "history_filter_all")
    static let historyFilterHigh = String(localized: "history_filter_high")
    static let historyFilterMedium = String(localized: "history_filter_medium")
    static let historyFilterLow = String(localized: "history_filter_low")
    static let historyPeriodThisWeek = String(localized: "history_period_this_week")
    static let historyNoRecords = String(localized: "history_no_records")
    static let historyNoRecordsHint = String(localized: "history_no_records_hint")

    // MARK: - Analysis
    static let analysisTitle = String(localized: "analysis_title")
    static let analysisLast30Days = String(localized: "analysis_last_30_days")
    static let analysisFactors = String(localized: "analysis_factors")
    static let analysisCorrelationsDetected = String(localized: "analysis_correlations_detected")
    static let analysisAiSummary = String(localized: "analysis_ai_summary")
    static let analysisHelpfulQuestion = String(localized: "analysis_helpful_question")
    static let analysisInsufficientData = String(localized: "analysis_insufficient_data")
    static let analysisRecommendedActions = String(localized: "analysis_recommended_actions")
    static let analysisCheckPressure = String(localized: "analysis_check_pressure")
    static let analysisPressureCorrelation = String(localized: "analysis_pressure_correlation")
    static let analysisSleepReminder = String(localized: "analysis_sleep_reminder")
    static let analysisSleepCorrelation = String(localized: "analysis_sleep_correlation")
    static let analysisContinueRecording = String(localized: "analysis_continue_recording")
    static let analysisForAccurate = String(localized: "analysis_for_accurate")

    // MARK: - Correlation
    static let correlationPressure = String(localized: "correlation_pressure")
    static let correlationTemperature = String(localized: "correlation_temperature")
    static let correlationHumidity = String(localized: "correlation_humidity")
    static let correlationSleep = String(localized: "correlation_sleep")
    static let correlationSteps = String(localized: "correlation_steps")
    static let correlationHeartRate = String(localized: "correlation_heart_rate")
    static let correlationStrong = String(localized: "correlation_strong")
    static let correlationModerate = String(localized: "correlation_moderate")
    static let correlationWeak = String(localized: "correlation_weak")
    static let correlationNegligible = String(localized: "correlation_negligible")

    // MARK: - Forecast View
    static let forecastViewTitle = String(localized: "forecast_view_title")
    static let forecastToday = String(localized: "forecast_today")
    static func forecastPredictionFor(_ date: String) -> String {
        String(localized: "forecast_prediction_for \(date)")
    }
    static let forecastPredictedRisk = String(localized: "forecast_predicted_risk")
    static let forecastChange = String(localized: "forecast_change")
    static let forecastTemperature = String(localized: "forecast_temperature")
    static let forecastPressureDropWarning = String(localized: "forecast_pressure_drop_warning")
    static let forecastPressureRising = String(localized: "forecast_pressure_rising")
    static let forecastPressureDropDetail = String(localized: "forecast_pressure_drop_detail")
    static let forecastPressureStableDetail = String(localized: "forecast_pressure_stable_detail")
    static let forecastRecommendedPrevention = String(localized: "forecast_recommended_prevention")

    // MARK: - Prevention
    static let preventionWarmBath = String(localized: "prevention_warm_bath")
    static let preventionWarmBathDesc = String(localized: "prevention_warm_bath_desc")
    static let preventionStretch = String(localized: "prevention_stretch")
    static let preventionStretchDesc = String(localized: "prevention_stretch_desc")
    static let preventionMedication = String(localized: "prevention_medication")
    static let preventionMedicationDesc = String(localized: "prevention_medication_desc")

    // MARK: - Risk Levels
    static let riskLow = String(localized: "risk_low")
    static let riskMedium = String(localized: "risk_medium")
    static let riskHigh = String(localized: "risk_high")
    static let riskVeryHigh = String(localized: "risk_very_high")

    // MARK: - Settings
    static let settingsTitle = String(localized: "settings_title")
    static let settingsNotifications = String(localized: "settings_notifications")
    static let settingsMorningNotification = String(localized: "settings_morning_notification")
    static let settingsMorningSubtitle = String(localized: "settings_morning_subtitle")
    static let settingsAfternoonNotification = String(localized: "settings_afternoon_notification")
    static let settingsEveningNotification = String(localized: "settings_evening_notification")
    static let settingsDataIntegration = String(localized: "settings_data_integration")
    static let settingsSleepData = String(localized: "settings_sleep_data")
    static let settingsStepCount = String(localized: "settings_step_count")
    static let settingsHeartRate = String(localized: "settings_heart_rate")
    static let settingsLocationWeather = String(localized: "settings_location_weather")
    static let settingsAccountSync = String(localized: "settings_account_sync")
    static let settingsCloudSync = String(localized: "settings_cloud_sync")
    static func settingsLastSync(_ time: String) -> String {
        String(localized: "settings_last_sync \(time)")
    }
    static let settingsJustNow = String(localized: "settings_just_now")
    static let settingsNotificationPermissionTitle = String(localized: "settings_notification_permission_title")
    static let settingsNotificationPermissionMessage = String(localized: "settings_notification_permission_message")
    static let settingsOpenSettings = String(localized: "settings_open_settings")

    // MARK: - Common
    static let commonCancel = String(localized: "common_cancel")
    static let commonSave = String(localized: "common_save")
    static let commonEdit = String(localized: "common_edit")
    static let commonDelete = String(localized: "common_delete")
    static let commonClose = String(localized: "common_close")

    // MARK: - Record Detail
    static let recordDetailTitle = String(localized: "record_detail_title")
    static let recordDetailDate = String(localized: "record_detail_date")
    static let recordDetailTime = String(localized: "record_detail_time")
    static let recordDetailBodyParts = String(localized: "record_detail_body_parts")
    static let recordDetailPainTypes = String(localized: "record_detail_pain_types")
    static let recordDetailWeather = String(localized: "record_detail_weather")
    static let recordDetailHealth = String(localized: "record_detail_health")
    static let recordDetailHumidity = String(localized: "record_detail_humidity")
    static let recordDetailNote = String(localized: "record_detail_note")
    static let recordDeleteButton = String(localized: "record_delete_button")
    static let recordDeleteConfirmTitle = String(localized: "record_delete_confirm_title")
    static let recordDeleteConfirmMessage = String(localized: "record_delete_confirm_message")

    // MARK: - Notification List
    static let notificationListTitle = String(localized: "notification_list_title")
    static let notificationListEmpty = String(localized: "notification_list_empty")
    static let notificationListEmptyHint = String(localized: "notification_list_empty_hint")

    // MARK: - Advice Detail
    static let adviceDetailBenefits = String(localized: "advice_detail_benefits")
    static let adviceDetailBenefit1 = String(localized: "advice_detail_benefit_1")
    static let adviceDetailBenefit2 = String(localized: "advice_detail_benefit_2")
    static let adviceDetailBenefit3 = String(localized: "advice_detail_benefit_3")
    static let adviceDetailTips = String(localized: "advice_detail_tips")
    static let adviceDetailTipsContent = String(localized: "advice_detail_tips_content")

    // MARK: - Profile
    static let profileTitle = String(localized: "profile_title")
    static let profileName = String(localized: "profile_name")
    static let profileNamePlaceholder = String(localized: "profile_name_placeholder")
    static let profileAge = String(localized: "profile_age")
    static let profileAgePlaceholder = String(localized: "profile_age_placeholder")
    static let profileNotSet = String(localized: "profile_not_set")
    static let profileStats = String(localized: "profile_stats")
    static let profileTotalRecords = String(localized: "profile_total_records")
    static let profileStreakDays = String(localized: "profile_streak_days")
    static let profileStartDate = String(localized: "profile_start_date")
    static let profileAbout = String(localized: "profile_about")
    static let profileVersion = String(localized: "profile_version")
    static let profileTerms = String(localized: "profile_terms")
    static let profilePrivacy = String(localized: "profile_privacy")

    // MARK: - Forecast Card (Dashboard)
    static let forecastCardTodayPrediction = String(localized: "forecast_card_today_prediction")
    static let forecastCardAiAnalysis = String(localized: "forecast_card_ai_analysis")
    static let forecastCardViewDetail = String(localized: "forecast_card_view_detail")

    // MARK: - Notifications
    static let notificationMorningTitle = String(localized: "notification_morning_title")
    static let notificationMorningBody = String(localized: "notification_morning_body")
    static let notificationEveningTitle = String(localized: "notification_evening_title")
    static let notificationEveningBody = String(localized: "notification_evening_body")
    static let notificationWeatherPressureDropTitle = String(localized: "notification_weather_pressure_drop_title")
    static let notificationWeatherPressureDropBody = String(localized: "notification_weather_pressure_drop_body")
    static let notificationWeatherPressureRiseTitle = String(localized: "notification_weather_pressure_rise_title")
    static let notificationWeatherPressureRiseBody = String(localized: "notification_weather_pressure_rise_body")
    static let notificationTrackingTitle = String(localized: "notification_tracking_title")
    static let notificationTrackingBody = String(localized: "notification_tracking_body")
    static let notificationActionViewForecast = String(localized: "notification_action_view_forecast")
    static let notificationActionDismiss = String(localized: "notification_action_dismiss")
    static let notificationActionRecordNow = String(localized: "notification_action_record_now")
    static let notificationActionRemindLater = String(localized: "notification_action_remind_later")

    // MARK: - PDF Report
    static let pdfReportTitle = String(localized: "pdf_report_title")
    static func pdfPatientName(_ name: String) -> String {
        String(localized: "pdf_patient_name \(name)")
    }
    static func pdfGeneratedDate(_ date: String) -> String {
        String(localized: "pdf_generated_date \(date)")
    }
    static let pdfSummary = String(localized: "pdf_summary")
    static let pdfRecordCount = String(localized: "pdf_record_count")
    static let pdfAvgPain = String(localized: "pdf_avg_pain")
    static let pdfMaxPain = String(localized: "pdf_max_pain")
    static let pdfMinPain = String(localized: "pdf_min_pain")
    static let pdfCorrelationAnalysis = String(localized: "pdf_correlation_analysis")
    static let pdfBodyPartAnalysis = String(localized: "pdf_body_part_analysis")
    static let pdfRecentRecords = String(localized: "pdf_recent_records")
    static let pdfAllRecords = String(localized: "pdf_all_records")
    static let pdfDatetime = String(localized: "pdf_datetime")
    static let pdfPainLevel = String(localized: "pdf_pain_level")
    static let pdfLocation = String(localized: "pdf_location")
    static let pdfFooter = String(localized: "pdf_footer")

    // MARK: - Insights
    static let insightMostCommonPart = String(localized: "insight_most_common_part")
    static let insightAvgPainLevel = String(localized: "insight_avg_pain_level")
    static let insightMainCorrelation = String(localized: "insight_main_correlation")
    static let insightRecordingStatus = String(localized: "insight_recording_status")
    static let insightContinueRecording = String(localized: "insight_continue_recording")
}

// MARK: - BodyPart Localized Name Extension
extension BodyPart {
    var localizedName: String {
        switch self {
        case .head: return String(localized: "body_part_head")
        case .neck: return String(localized: "body_part_neck")
        case .leftShoulder: return String(localized: "body_part_left_shoulder")
        case .rightShoulder: return String(localized: "body_part_right_shoulder")
        case .upperBack: return String(localized: "body_part_upper_back")
        case .lowerBack: return String(localized: "body_part_lower_back")
        case .chest: return String(localized: "body_part_chest")
        case .abdomen: return String(localized: "body_part_abdomen")
        case .leftArm: return String(localized: "body_part_left_arm")
        case .rightArm: return String(localized: "body_part_right_arm")
        case .leftHand: return String(localized: "body_part_left_hand")
        case .rightHand: return String(localized: "body_part_right_hand")
        case .leftHip: return String(localized: "body_part_left_hip")
        case .rightHip: return String(localized: "body_part_right_hip")
        case .leftKnee: return String(localized: "body_part_left_knee")
        case .rightKnee: return String(localized: "body_part_right_knee")
        case .leftLeg: return String(localized: "body_part_left_leg")
        case .rightLeg: return String(localized: "body_part_right_leg")
        case .leftFoot: return String(localized: "body_part_left_foot")
        case .rightFoot: return String(localized: "body_part_right_foot")
        }
    }
}

// MARK: - CorrelationFactor Localized Name Extension
extension CorrelationFactor {
    var localizedName: String {
        switch self {
        case .pressure: return L10n.correlationPressure
        case .temperature: return L10n.correlationTemperature
        case .humidity: return L10n.correlationHumidity
        case .sleepDuration: return L10n.correlationSleep
        case .stepCount: return L10n.correlationSteps
        case .heartRate: return L10n.correlationHeartRate
        }
    }
}

// MARK: - CorrelationStrength Localized Name Extension
extension CorrelationStrength {
    var localizedName: String {
        switch self {
        case .strong: return L10n.correlationStrong
        case .moderate: return L10n.correlationModerate
        case .weak: return L10n.correlationWeak
        case .negligible: return L10n.correlationNegligible
        }
    }
}

// MARK: - RiskLevel Localized Name Extension
extension RiskLevel {
    var localizedName: String {
        switch self {
        case .low: return L10n.riskLow
        case .medium: return L10n.riskMedium
        case .high: return L10n.riskHigh
        case .veryHigh: return L10n.riskVeryHigh
        }
    }
}
