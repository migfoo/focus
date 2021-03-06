<?php
/**
 * @file
 * FOCUS Distribution Profile.
 */

module_load_include('inc', 'focus', 'includes/debug');
module_load_include('inc', 'focus', 'includes/libraries');
module_load_include('inc', 'focus', 'includes/preprocess');

/**
 * Implements hook_init().
 */
function focus_init() {
    // Login page should always be /user.
    if (user_is_anonymous() && $_GET['q'] == 'user/login') {
        drupal_goto('user');
    }
}

/**
 * Implements hook_views_api().
 */
function focus_views_api() {
    return array(
        'api' => 3,
    );
}

/**
 * Implements hook_custom_theme().
 */
function focus_custom_theme() {
    switch ($_GET['q']) {
        case 'user':
        case 'user/password':
        case 'user/register':
            return variable_get('admin_theme', variable_get('theme_default'));
    }
}

/**
 * Implements hook_admin_paths().
 */
function focus_admin_paths() {
    if (variable_get('node_admin_theme')) {
        $paths = array(
            'user'   => TRUE,
            'user/*' => TRUE,
            'node/*/log' => TRUE,
            'node/*/track' => TRUE,
            'node/*/revisions/*/list' => TRUE,
        );

        return $paths;
    }
}

/**
 * Implements hook_media_wysiwyg_token_to_markup_alter().
 */
function focus_media_wysiwyg_token_to_markup_alter(&$element, &$tag_info, &$settings) {
    // Add a class to the element container to reflect float styles.
    $file =& $element['content']['file'];
    if (!empty($file['#attributes']['style'])) {
        preg_match_all('#float\:[\s]?(.*?)\;#i', $file['#attributes']['style'], $floats);
        foreach (@$floats[1] as $float) {
            $element['content']['#attributes']['class'][] = 'media-' . $float;
        }
    }
}

/**
 * Implements hook_theme_registry_alter()
 */
function focus_theme_registry_alter(&$theme_registry) {
    // TODO: Move to theme.
    $theme_registry['colorbox_image_formatter']['preprocess functions'][] = 'focus_colorbox_image_formatter_preprocess';
}

/**
 * Theme preprocessor
 * Adds fielded values to file itself
 */
function focus_colorbox_image_formatter_preprocess(&$vars) {
    // set alt to fielded alt
    if (!empty($vars['item']['field_file_image_alt_text'][LANGUAGE_NONE][0]['value'])) {
        $vars['item']['alt'] = $vars['item']['field_file_image_alt_text'][LANGUAGE_NONE][0]['value'];
    }

    // set title to fielded title
    if (!empty($vars['item']['field_file_image_title_text'][LANGUAGE_NONE][0]['value'])) {
        $vars['item']['title'] = $vars['item']['field_file_image_title_text'][LANGUAGE_NONE][0]['value'];
    }
}

/**
 * Theme preprocessor
 * Adds fielded values to field slideshow file itself
 */
function focus_preprocess_field_slideshow(&$vars) {
    foreach ($vars['items'] as $num => &$item) {
        if (!empty($item['field_file_image_title_text'][LANGUAGE_NONE][0]['value'])) {
            $item['caption'] = $item['field_file_image_title_text'][LANGUAGE_NONE][0]['value'];
            $item['title']   = $item['field_file_image_title_text'][LANGUAGE_NONE][0]['value'];
            $item['path']['options']['attributes']['title'] = $item['caption'];
            $item['caption_path']['options']['attributes']['title'] = $item['caption'];
            $rebuild = TRUE;
        }

        if (!empty($item['field_file_image_alt_text'][LANGUAGE_NONE][0]['value'])) {
            $item['alt'] = $item['field_file_image_alt_text'][LANGUAGE_NONE][0]['value'];
            $rebuild = TRUE;
        }
    }

    if (!empty($rebuild)) {
        template_preprocess_field_slideshow($vars);
    }
}

/**
 * Implements hook_preprocess_html().
 */
function focus_preprocess_html(&$vars) {
    // if we're using JIRA Issue Collector, override the styles.
    if (module_exists('jira_issue_collector')) {
        if (variable_get('node_admin_theme', FALSE)) {
            $theme = variable_get('admin_theme', 'bartik');
        }
        else {
            $theme = variable_get('theme_default', 'bartik');
        }

        $path = drupal_get_path('theme', $theme);
        if (file_exists("$path/css/jira.css")) {
            drupal_add_css("$path/css/jira.css", array(
                'group'  => CSS_THEME,
                'weight' => 20,
            ));
        }
        else {
            // If no theme customizes the jira button, use the simplicity.
            drupal_add_css(drupal_get_path('theme', 'simplicity') .'/css/jira.css');
        }
    }
}

/**
 * Implements hook_wysiwyg_editor_settings_alter().
 *
 * @see http://drupal.org/node/1951964
 */
function focus_wysiwyg_editor_settings_alter(&$settings, $context) {
    if ($context['profile']->editor == 'ckeditor') {
        $settings['allowedContent'] = TRUE;
    }
}

/**
 * Implements hook_page_build().
 */
function focus_page_build(&$page) {
    // Add Legacy Browser Warning.
    $page['page_top']['focus_legacy'] = array(
        '#type' => 'container',
        '#attributes' => array('class' => 'chromeframe'),
        '#weight' => -1000,
        '#prefix' => t('<!--[if lte IE 7]>'),
        '#suffix' => t('<![endif]-->'),
        'content' => array(
            '#type' => 'html_tag',
            '#tag' => 'p',
            '#value' => t('You are using an <em>outdated</em> browser.  Please !upgrade or !chromeframe to improve your experience.', array(
                '!upgrade' => l('upgrade your browser', 'http://browsehappy.com', array(
                    'attributes' => array(
                        'target' => '_blank',
                    ),
                )),
                '!chromeframe' => l('activate Google Chrome Frame', 'http://www.google.com/chromeframe/', array(
                    'query' => array('redirect' => 'true'),
                )),
            )),
        ),
    );
}