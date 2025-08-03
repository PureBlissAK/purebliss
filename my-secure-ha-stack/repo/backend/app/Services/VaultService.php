<?php
// app/Services/VaultService.php

namespace App\Services;

use GuzzleHttp\Client;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class VaultService
{
    protected $client;
    protected $vaultUrl;
    protected $vaultToken;

    public function __construct()
    {
        $this->vaultUrl = config('vault.url');
        $this->vaultToken = config('vault.token');
        $this->client = new Client([
            'base_uri' => $this->vaultUrl,
            'timeout'  => 5.0,
        ]);
    }

    /**
     * Fetch dynamic credentials from Vault for a given path.
     *
     * @param string $path
     * @return array|null
     */
    public function getDynamicSecret(string $path): ?array
    {
        try {
            $cacheKey = 'vault_secret_' . md5($path);
            return Cache::remember($cacheKey, 300, function () use ($path) {
                $response = $this->client->get('/v1/' . ltrim($path, '/'), [
                    'headers' => [
                        'X-Vault-Token' => $this->vaultToken,
                    ],
                ]);
                $data = json_decode($response->getBody()->getContents(), true);
                return $data['data'] ?? null;
            });
        } catch (\Exception $e) {
            Log::error('VaultService error: ' . $e->getMessage());
            return null;
        }
    }
}
