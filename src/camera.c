/* Northstar — webcam enumeration (V4L2) and per-site camera permission.
 * Copyright 2026 Andreas Røsdal
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "camera.h"

#include <string.h>

#include "js.h"
#include "net.h"

static GHashTable *g_camera_decisions;
static char *g_camera_pending;

void
ns_camera_info_free(ns_camera_info *info)
{
    if (!info) return;
    g_free(info->device);
    g_free(info->label);
    g_free(info);
}

static void
ns_camera_record_decision(const char *origin, gboolean allow)
{
    if (!g_camera_decisions)
        g_camera_decisions = g_hash_table_new_full(g_str_hash, g_str_equal,
                                                   g_free, NULL);
    g_hash_table_insert(g_camera_decisions, g_strdup(origin),
                        GINT_TO_POINTER(allow ? 1 : 2));
}

gboolean
ns_camera_has_pending_origin(void)
{
    return g_camera_pending != NULL;
}

char *
ns_camera_take_pending_origin(void)
{
    char *origin = g_camera_pending;
    g_camera_pending = NULL;
    return origin;
}

void
ns_camera_set_decision(const char *origin, int allow)
{
    if (!origin || !*origin) return;
    ns_camera_record_decision(origin, allow ? TRUE : FALSE);
    if (g_camera_pending && g_strcmp0(g_camera_pending, origin) == 0)
        g_clear_pointer(&g_camera_pending, g_free);
}

int
ns_camera_permission(ns_js *js)
{
    const char *url = ns_js_current_url(js);
    char *origin = ns_url_origin_from(url);
    if (!origin || !*origin) {
        g_free(origin);
        origin = g_strdup("this page");
    }

    if (!g_camera_decisions)
        g_camera_decisions = g_hash_table_new_full(g_str_hash, g_str_equal,
                                                   g_free, NULL);
    gpointer prev = NULL;
    if (g_hash_table_lookup_extended(g_camera_decisions, origin, NULL, &prev)) {
        int v = GPOINTER_TO_INT(prev);
        g_free(origin);
        if (v == 1) return 1;
        if (v == 2) return 0;
        return -1;
    }

    const char *allow_env = g_getenv("NS_CAMERA_ALLOW");
    if (allow_env && allow_env[0] == '1') {
        ns_camera_record_decision(origin, TRUE);
        g_free(origin);
        return 1;
    }

    g_hash_table_insert(g_camera_decisions, g_strdup(origin),
                        GINT_TO_POINTER(3));
    g_free(g_camera_pending);
    g_camera_pending = g_strdup(origin);
    g_free(origin);
    return -1;
}

#if defined(__linux__)

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/videodev2.h>

static int
xioctl(int fd, unsigned long req, void *arg)
{
    int r;
    do { r = ioctl(fd, req, arg); } while (r < 0 && errno == EINTR);
    return r;
}

static char *
ns_camera_label_for(const char *device)
{
    int fd = open(device, O_RDWR | O_NONBLOCK | O_CLOEXEC);
    if (fd < 0) return NULL;
    struct v4l2_capability cap;
    memset(&cap, 0, sizeof cap);
    char *label = NULL;
    if (xioctl(fd, VIDIOC_QUERYCAP, &cap) == 0 &&
        (cap.capabilities & V4L2_CAP_VIDEO_CAPTURE) &&
        cap.card[0])
        label = g_strdup((const char *)cap.card);
    close(fd);
    return label;
}

GPtrArray *
ns_camera_enumerate(void)
{
    GPtrArray *out = g_ptr_array_new();
    for (int i = 0; i < 64; i++) {
        char dev[32];
        g_snprintf(dev, sizeof dev, "/dev/video%d", i);
        if (!g_file_test(dev, G_FILE_TEST_EXISTS)) continue;
        char *label = ns_camera_label_for(dev);
        if (!label) continue;
        ns_camera_info *info = g_new0(ns_camera_info, 1);
        info->device = g_strdup(dev);
        info->label = label;
        g_ptr_array_add(out, info);
    }
    return out;
}

#else

GPtrArray *ns_camera_enumerate(void) { return g_ptr_array_new(); }

#endif
