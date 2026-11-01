/*
 * Copyright 2026 Anton Tananaev (anton@traccar.org)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.traccar.api.resource;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.traccar.config.Config;
import org.traccar.config.Keys;
import org.traccar.database.StatisticsManager;
import org.traccar.model.Server;
import org.traccar.storage.Storage;
import org.traccar.storage.StorageException;
import org.traccar.storage.query.Request;

import jakarta.ws.rs.core.Response;
import java.lang.reflect.Field;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

public class HealthResourceTest {

    private Config config;
    private StatisticsManager statisticsManager;
    private Storage storage;
    private HealthResource resource;

    private static void setField(Object target, String name, Object value) throws Exception {
        Field field = HealthResource.class.getDeclaredField(name);
        field.setAccessible(true);
        field.set(target, value);
    }

    @BeforeEach
    public void setUp() throws Exception {
        // message counters are static, reset them so tests do not depend on order
        setField(null, "messageLastTotal", 0L);
        setField(null, "messageLastCheck", 0L);

        config = mock(Config.class);
        statisticsManager = mock(StatisticsManager.class);
        storage = mock(Storage.class);

        resource = new HealthResource();
        setField(resource, "config", config);
        setField(resource, "statisticsManager", statisticsManager);
        setField(resource, "storage", storage);
    }

    @Test
    public void testOkWhenStorageAnswers() throws Exception {
        when(storage.getObject(eq(Server.class), any(Request.class))).thenReturn(new Server());

        Response response = resource.health();

        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        assertEquals("OK", response.getEntity());
    }

    @Test
    public void testErrorWhenStorageThrows() throws Exception {
        when(storage.getObject(eq(Server.class), any(Request.class))).thenThrow(new StorageException("down"));

        Response response = resource.health();

        assertEquals(Response.Status.INTERNAL_SERVER_ERROR.getStatusCode(), response.getStatus());
    }

    @Test
    public void testErrorWhenMessagesDropBelowThreshold() throws Exception {
        when(storage.getObject(eq(Server.class), any(Request.class))).thenReturn(new Server());
        when(config.getDouble(Keys.WEB_HEALTH_CHECK_DROP_THRESHOLD)).thenReturn(0.5);
        // checks: 100 messages, then 10 messages (ratio 0.1)
        when(statisticsManager.messageStoredCount()).thenReturn(100, 110);

        assertEquals(Response.Status.OK.getStatusCode(), resource.health().getStatus());
        assertEquals(Response.Status.INTERNAL_SERVER_ERROR.getStatusCode(), resource.health().getStatus());
    }

    @Test
    public void testOkWhenMessagesStayAboveThreshold() throws Exception {
        when(storage.getObject(eq(Server.class), any(Request.class))).thenReturn(new Server());
        when(config.getDouble(Keys.WEB_HEALTH_CHECK_DROP_THRESHOLD)).thenReturn(0.5);
        // checks: 100 messages, then 80 messages (ratio 0.8)
        when(statisticsManager.messageStoredCount()).thenReturn(100, 180);

        assertEquals(Response.Status.OK.getStatusCode(), resource.health().getStatus());
        assertEquals(Response.Status.OK.getStatusCode(), resource.health().getStatus());
    }

    @Test
    public void testOkWhenNoThreshold() throws Exception {
        when(storage.getObject(eq(Server.class), any(Request.class))).thenReturn(new Server());
        when(config.getDouble(Keys.WEB_HEALTH_CHECK_DROP_THRESHOLD)).thenReturn(0.0);
        // same drop as the threshold test, but the check is disabled
        when(statisticsManager.messageStoredCount()).thenReturn(100, 110);

        assertEquals(Response.Status.OK.getStatusCode(), resource.health().getStatus());
        assertEquals(Response.Status.OK.getStatusCode(), resource.health().getStatus());
    }

}
