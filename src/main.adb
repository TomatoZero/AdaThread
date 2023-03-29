with Ada.Text_IO, Ada.Calendar;
use Ada.Text_IO, Ada.Calendar;

procedure Main is


   task type new_main_task (Size : Positive) is
      pragma Storage_Size (Size);
   end new_main_task;

   task body new_main_task is
      type MinType is array (1 .. 2) of Integer;

      Dimension     : Integer := 50_000_000;
      MyArray       : array (1 .. Dimension) of Integer;
      num_tasks     : Integer := 50;
      min_dimension : Integer;

      min : MinType := (Dimension, Dimension);

      start_time, end_time : Time;
      work_time            : Duration;

      procedure InitArray is
      begin

         for i in MyArray'Range loop
            MyArray (i) := i;
         end loop;

         MyArray (100_000) := -10;

      end InitArray;

      function Part_Min (start_index, end_index : Integer) return MinType is
         min : MinType := (Dimension, Dimension);
      begin

         for i in start_index .. end_index loop
            if min (1) > MyArray (i) then
               min (1) := MyArray (i);
               min (2) := i;
            end if;
         end loop;

         return min;
      end Part_Min;

      protected task_manager is

         procedure add_thread_result (min : in MinType);
         entry get_result (min : out MinType);

      private
         min   : MinType := (Dimension, Dimension);
         Count : Integer := 0;
      end task_manager;

      protected body task_manager is

         procedure add_thread_result (min : in MinType) is
         begin

            if task_manager.min > min then
               task_manager.min := min;
            end if;

            Count := Count + 1;
         end add_thread_result;

         entry get_result (min : out MinType) when Count = num_tasks is
         begin
            min := task_manager.min;
         end get_result;

      end task_manager;

      task type parallel_min is
         entry Start (start_index, end_index : in Integer);
      end parallel_min;

      task body parallel_min is
         min                    : MinType;
         start_index, end_index : Integer;
      begin
         accept Start (start_index : in Integer; end_index : in Integer) do
            parallel_min.start_index := start_index;
            parallel_min.end_index   := end_index;
         end Start;

         min := Part_Min (start_index, end_index);
         task_manager.add_thread_result (min);

      end parallel_min;

      tasks : array (1 .. num_tasks) of parallel_min;
      j     : Integer := 1;

   begin

      InitArray;
      min_dimension := Dimension / num_tasks;

      start_time := Clock;
      min        := Part_Min (1, Dimension);
      end_time   := Clock;
      work_time  := end_time - start_time;
      Put_Line
        ("Min: " & min (1)'Img & " Index: " & min (2)'Img & " Work time: " &
           work_time'Img);

      start_time := Clock;

      for i in 1 .. num_tasks loop

         if (Dimension rem num_tasks /= 0) and i = num_tasks then
            tasks (i).Start (j, Dimension);
         else
            tasks (i).Start (j, j + min_dimension - 1);
         end if;

         j := j + min_dimension;
      end loop;

      task_manager.get_result (min);

      end_time  := Clock;
      work_time := end_time - start_time;
      Put_Line
        ("Min: " & min (1)'Img & " Index: " & min (2)'Img & " Work time: " &
           work_time'Img);
   end new_main_task;

   new_main : new_main_task (1_000_000_000);

begin
   null;
end Main;
