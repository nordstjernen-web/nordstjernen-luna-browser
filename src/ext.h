/* Nordstjernen Web Browser — WebExtensions loader and content-script host.
 * Copyright 2026 Andreas Røsdal
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef NS_EXT_H
#define NS_EXT_H

#include <glib.h>
#include "quickjs_compat.h"

G_BEGIN_DECLS

/* Move extensions from their previous location inside the writable profile
 * directory; call before the sandbox is set up. */
void     ns_ext_migrate_default_dir(void);
/* Remove any leftover content-script helper functions from a global. */
void     ns_ext_drop_helpers(JSContext *ctx);
char    *ns_ext_content_scripts_for_url(JSContext *ctx, JSValueConst global,
                                        const char *url, gboolean at_start);
gboolean ns_ext_should_block(const char *url, const char *initiator);
gboolean ns_ext_resource_load(const char *url, GBytes **bytes,
                              char **content_type, char **error);
G_END_DECLS

#endif
