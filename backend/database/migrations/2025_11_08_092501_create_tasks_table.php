<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('tasks', function (Blueprint $table) {
            $table->uuid('uuid')->primary();
            $table->string('title')->nullable();
            $table->text('description')->nullable();
            $table->string('key')->nullable();
            $table->string('status')->nullable();
            $table->string('assignee')->nullable();
            $table->string('owner')->nullable();
            $table->string('reporter')->nullable();
            $table->dateTime('due_date')->nullable();
            $table->string('priority')->nullable();
            $table->string('parent_id')->nullable();
            $table->string('task_type_id')->nullable();
            $table->string('space_id')->nullable();
            $table->dateTime('created_date')->nullable();
            $table->dateTime('updated_date')->nullable();
            $table->dateTime('deleted_date')->nullable();
            $table->string('created_by')->nullable();
            $table->string('updated_by')->nullable();
            $table->string('deleted_by')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tasks');
    }
};
