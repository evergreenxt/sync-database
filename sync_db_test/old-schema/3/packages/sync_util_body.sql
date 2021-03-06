/*
 * Copyright (c) 2013 Citrix Systems, Inc.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

create or replace package body sync_util as
    --------------------------------------------------------------------------
    -- Public procedures and functions.
    --------------------------------------------------------------------------

    procedure check_device_exists(
        device_uuid in varchar2,
        lock_row    in boolean := false
    ) is
        dummy varchar2(1);
    begin
        if device_uuid is null then
            sync_error.raise(sync_error.device_required);
        end if;

        begin
            if lock_row then
                select null
                into check_device_exists.dummy
                from device
                where device_uuid = check_device_exists.device_uuid
                for update;
            else
                select null
                into check_device_exists.dummy
                from device
                where device_uuid = check_device_exists.device_uuid;
            end if;
        exception
            when no_data_found then
                sync_error.raise(sync_error.device_not_found,
                                 device_uuid);
        end;
    end;

    procedure check_database_state is
        current_version version.current_version%type;
        installing_version version.installing_version%type;
    begin
        begin
            select current_version,
                   installing_version
            into check_database_state.current_version,
                 check_database_state.installing_version
            from version;
        exception
            when no_data_found then
                sync_error.raise(sync_error.db_state_invalid);
            when too_many_rows then
                sync_error.raise(sync_error.db_state_invalid);
        end;

        if installing_version is not null then
            if current_version is not null then
                sync_error.raise(sync_error.upgrade_incomplete);
            else
                sync_error.raise(sync_error.installation_incomplete);
            end if;
        end if;
    end;

    procedure lock_device_row(
        device_uuid in varchar2
    ) is
    begin
        check_device_exists(device_uuid, true);
    end;
end;
/
