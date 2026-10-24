/*
 * SPDX-License-Identifier: Apache-2.0
 */

package org.zeroroms.tools;

import android.os.BugreportManager;
import android.os.BugreportParams;
import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;
import android.util.Log;
import android.widget.Toast;

/**
 * Quick settings tile that starts Android's interactive bug report. Android's Shell app does the
 * rest: it shows progress in a notification and offers to share the report when it is ready. The
 * tile asks for the phone to be unlocked first, since a bug report holds personal data.
 */
public class BugReportTileService extends TileService {

    private static final String TAG = "ZeroSBugReportTile";

    @Override
    public void onStartListening() {
        Tile tile = getQsTile();
        if (tile == null) {
            return;
        }
        tile.setState(Tile.STATE_INACTIVE);
        tile.updateTile();
    }

    @Override
    public void onClick() {
        if (isLocked()) {
            unlockAndRun(this::requestBugReport);
        } else {
            requestBugReport();
        }
    }

    private void requestBugReport() {
        BugreportManager manager = getSystemService(BugreportManager.class);
        if (manager == null) {
            Log.e(TAG, "BugreportManager is not available");
            return;
        }
        try {
            manager.requestBugreport(
                    new BugreportParams(BugreportParams.BUGREPORT_MODE_INTERACTIVE), null, null);
        } catch (RuntimeException e) {
            // A SecurityException means DUMP was not granted (privapp allowlist missing)
            Log.e(TAG, "Bug report request failed", e);
            return;
        }
        Toast.makeText(this, R.string.bug_report_started, Toast.LENGTH_LONG).show();
    }
}
